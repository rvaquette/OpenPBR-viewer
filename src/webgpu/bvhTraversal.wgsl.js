export const BVH_TRAVERSAL_WGSL = /* wgsl */ `
struct BvhNode { minimum: vec4<f32>, maximum: vec4<f32>, metadata: vec4<f32> }
struct TriangleIndices { indices: vec4<u32> }
struct BvhHit { found: bool, distance: f32, barycentric: vec3<f32>, normal: vec3<f32>, triangle: vec3<u32> }

fn bvhAabbIntersect(minimum: vec3<f32>, maximum: vec3<f32>, origin: vec3<f32>, direction: vec3<f32>) -> f32 {
    let inverseDirection = 1.0 / direction;
    let entry = min((minimum - origin) * inverseDirection, (maximum - origin) * inverseDirection);
    let exit = max((minimum - origin) * inverseDirection, (maximum - origin) * inverseDirection);
    let nearDistance = max(entry.x, max(entry.y, entry.z));
    let farDistance = min(exit.x, min(exit.y, exit.z));
    if (farDistance < max(nearDistance, 0.0)) { return 1.0e20; }
    return max(nearDistance, 0.0);
}

fn bvhTrace(origin: vec3<f32>, direction: vec3<f32>, maxDistance: f32) -> BvhHit {
    var hit = BvhHit(false, maxDistance, vec3<f32>(0.0), vec3<f32>(0.0, 0.0, 1.0), vec3<u32>(0u));
    var stack: array<u32, 128>;
    var stackSize = 1u;
    stack[0] = 0;
    for (var visit = 0u; visit < frame.nodeCount; visit += 1u) {
        if (stackSize == 0u) { break; }
        stackSize -= 1u;
        let nodeIndex = stack[stackSize];
        if (nodeIndex >= frame.nodeCount) { atomicAdd(&bvhStackOverflow, 1u); break; }
        if (frame.debugMode == 18u && nodeIndex == 12u) {
            hit.found = true;
            hit.distance = 1.0;
            break;
        }
        let node = bvhNodes[nodeIndex];
        if (bvhAabbIntersect(node.minimum.xyz, node.maximum.xyz, origin, direction) > hit.distance) { continue; }
        if (node.metadata.z > 0.5) {
            let offset = u32(node.metadata.x + 0.5);
            let count = u32(node.metadata.y + 0.5);
            for (var triangle = 0u; triangle < count; triangle += 1u) {
                if (offset + triangle >= frame.triangleCount) { atomicAdd(&bvhStackOverflow, 1u); break; }
                let vertexIndices = bvhIndices[offset + triangle].indices.xyz;
                let p0 = bvhPositions[vertexIndices.x].xyz;
                let p1 = bvhPositions[vertexIndices.y].xyz;
                let p2 = bvhPositions[vertexIndices.z].xyz;
                let edge0 = p1 - p0;
                let edge1 = p2 - p0;
                let pvec = cross(direction, edge1);
                let determinant = dot(edge0, pvec);
                if (abs(determinant) < 1.0e-8) { continue; }
                let inverseDeterminant = 1.0 / determinant;
                let tvec = origin - p0;
                let qvec = cross(tvec, edge0);
                let u = dot(tvec, pvec) * inverseDeterminant;
                let v = dot(direction, qvec) * inverseDeterminant;
                let distance = dot(edge1, qvec) * inverseDeterminant;
                if (u >= 0.0 && v >= 0.0 && u + v <= 1.0 && distance > 0.0 && distance < hit.distance) {
                    let barycentric = vec3<f32>(1.0 - u - v, u, v);
                    let geometricNormal = normalize(cross(edge0, edge1));
                    let shadingNormal = normalize(
                        bvhNormals[vertexIndices.x].xyz * barycentric.x +
                        bvhNormals[vertexIndices.y].xyz * barycentric.y +
                        bvhNormals[vertexIndices.z].xyz * barycentric.z);
                    hit = BvhHit(true, distance, barycentric, select(geometricNormal, shadingNormal, length(shadingNormal) > 1.0e-5), vertexIndices);
                }
            }
        } else {
            if (stackSize + 2u > 128u) { atomicAdd(&bvhStackOverflow, 1u); continue; }
            stack[stackSize] = u32(node.metadata.y + 0.5); stackSize += 1u;
            stack[stackSize] = u32(node.metadata.x + 0.5); stackSize += 1u;
        }
    }
    return hit;
}`;