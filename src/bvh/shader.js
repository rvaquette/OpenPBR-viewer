export const nativeBvhShader = `
vec4 nativeBvhTexelFetch1D(sampler2D texture_, int index) {
    int width = textureSize(texture_, 0).x;
    return texelFetch(texture_, ivec2(index % width, index / width), 0);
}

vec4 textureSampleBarycoord(sampler2D texture_, vec3 barycoord, uvec3 faceIndices) {
    return barycoord.x * nativeBvhTexelFetch1D(texture_, int(faceIndices.x)) +
           barycoord.y * nativeBvhTexelFetch1D(texture_, int(faceIndices.y)) +
           barycoord.z * nativeBvhTexelFetch1D(texture_, int(faceIndices.z));
}

void ndcToCameraRay(vec2 coordinate, mat4 cameraWorld, mat4 inverseProjection,
                    out vec3 rayOrigin, out vec3 rayDirection) {
    vec4 lookDirection = cameraWorld * vec4(0.0, 0.0, -1.0, 0.0);
    vec4 nearVector = inverseProjection * vec4(0.0, 0.0, -1.0, 1.0);
    float nearDistance = abs(nearVector.z / nearVector.w);
    vec4 origin = cameraWorld * vec4(0.0, 0.0, 0.0, 1.0);
    vec4 direction = inverseProjection * vec4(coordinate, 0.5, 1.0);
    direction /= direction.w;
    direction = cameraWorld * direction - origin;
    origin.xyz += direction.xyz * nearDistance / dot(direction, lookDirection);
    rayOrigin = origin.xyz;
    rayDirection = direction.xyz;
}

float nativeBvhAabbIntersect(vec3 minimum, vec3 maximum, vec3 origin, vec3 direction) {
    vec3 inverseDirection = 1.0 / direction;
    vec3 t0 = (minimum - origin) * inverseDirection;
    vec3 t1 = (maximum - origin) * inverseDirection;
    vec3 entry = min(t0, t1);
    vec3 exit = max(t0, t1);
    float nearDistance = max(entry.x, max(entry.y, entry.z));
    float farDistance = min(exit.x, min(exit.y, exit.z));
    return farDistance >= max(nearDistance, 0.0) ? max(nearDistance, 0.0) : 1.0e20;
}

bool nativeBvhIntersectFirstHitWithinDistance(
    sampler2D nodes, sampler2D indices, sampler2D positions,
    vec3 rayOrigin, vec3 rayDirection, float maxDistance,
    inout uvec4 faceIndices, inout vec3 faceNormal, inout vec3 barycoord,
    inout float side, inout float dist) {
    int stack[64];
    int pointer = 0;
    stack[0] = 0;
    float closest = maxDistance;
    bool found = false;
    while (pointer >= 0 && pointer < 64) {
        int nodeIndex = stack[pointer--];
        vec4 minimum = nativeBvhTexelFetch1D(nodes, nodeIndex * 3);
        vec4 maximum = nativeBvhTexelFetch1D(nodes, nodeIndex * 3 + 1);
        vec4 metadata = nativeBvhTexelFetch1D(nodes, nodeIndex * 3 + 2);
        if (nativeBvhAabbIntersect(minimum.xyz, maximum.xyz, rayOrigin, rayDirection) > closest) continue;
        if (metadata.z > 0.5) {
            int offset = int(metadata.x + 0.5);
            int count = int(metadata.y + 0.5);
            for (int triangle = 0; triangle < count; triangle++) {
                uvec3 vertexIndices = uvec3(nativeBvhTexelFetch1D(indices, offset + triangle).xyz + 0.5);
                vec3 p0 = nativeBvhTexelFetch1D(positions, int(vertexIndices.x)).xyz;
                vec3 p1 = nativeBvhTexelFetch1D(positions, int(vertexIndices.y)).xyz;
                vec3 p2 = nativeBvhTexelFetch1D(positions, int(vertexIndices.z)).xyz;
                vec3 edge0 = p1 - p0;
                vec3 edge1 = p2 - p0;
                vec3 pvec = cross(rayDirection, edge1);
                float determinant = dot(edge0, pvec);
                if (abs(determinant) < 1.0e-8) continue;
                float inverseDeterminant = 1.0 / determinant;
                vec3 tvec = rayOrigin - p0;
                float u = dot(tvec, pvec) * inverseDeterminant;
                vec3 qvec = cross(tvec, edge0);
                float v = dot(rayDirection, qvec) * inverseDeterminant;
                float distance = dot(edge1, qvec) * inverseDeterminant;
                if (u >= 0.0 && v >= 0.0 && u + v <= 1.0 && distance > 0.0 && distance < closest) {
                    closest = distance;
                    dist = distance;
                    barycoord = vec3(1.0 - u - v, u, v);
                    faceIndices = uvec4(vertexIndices, 0u);
                    faceNormal = normalize(cross(edge0, edge1));
                    side = determinant < 0.0 ? -1.0 : 1.0;
                    found = true;
                }
            }
        } else {
            int left = int(metadata.x + 0.5);
            int right = int(metadata.y + 0.5);
            if (pointer + 2 >= 64) continue;
            stack[++pointer] = right;
            stack[++pointer] = left;
        }
    }
    return found;
}
`;