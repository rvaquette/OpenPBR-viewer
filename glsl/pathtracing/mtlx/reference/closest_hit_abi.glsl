#ifdef REFERENCE_BVH_ENABLED
precision highp isampler2D;
#define INF 1.0e20

uniform sampler2D BVH;
uniform isampler2D vertexIndicesTex;
uniform sampler2D verticesTex;
uniform sampler2D normalsTex;
uniform sampler2D transformsTex;
uniform int topBVHIndex;
uniform int referenceNodeCount;
uniform int referenceInstanceCount;

struct Ray
{
    vec3 origin;
    vec3 direction;
};

struct State
{
    int depth;
    float hitDist;
    vec3 fhp;
    vec3 normal;
    vec3 ffnormal;
    vec3 tangent;
    vec3 bitangent;
    vec3 geometricNormal;
    vec3 barycentric;
    ivec3 triangleIndices;
    vec2 texCoord;
    int matID;
    bool isEmitter;
    bool traversalOverflow;
#ifdef REFERENCE_BVH_DEBUG
    int debugNode;
    int debugLeaf;
    int debugTriangles;
    vec4 debugUvt;
#endif
};

struct LightSampleRec
{
    float pdf;
    vec3 emission;
};

vec4 texelFetch(sampler2D tex, int index)
{
    int width = textureSize(tex, 0).x;
    return texelFetch(tex, ivec2(index % width, index / width), 0);
}

ivec4 texelFetchI(isampler2D tex, int index)
{
    int width = textureSize(tex, 0).x;
    return texelFetch(tex, ivec2(index % width, index / width), 0);
}

vec4 texelFetch1D(sampler2D tex, int index)
{
    return texelFetch(tex, index);
}

float AABBIntersect(vec3 minCorner, vec3 maxCorner, Ray ray)
{
    float nearDistance = -INF;
    float farDistance = INF;
    for (int axis = 0; axis < 3; axis++)
    {
        float origin = ray.origin[axis];
        float direction = ray.direction[axis];
        if (abs(direction) <= 1.0e-20)
        {
            if (origin < minCorner[axis] || origin > maxCorner[axis])
                return -1.0;
        }
        else
        {
            float first = (minCorner[axis] - origin) / direction;
            float second = (maxCorner[axis] - origin) / direction;
            nearDistance = max(nearDistance, min(first, second));
            farDistance = min(farDistance, max(first, second));
            if (farDistance < nearDistance)
                return -1.0;
        }
    }
    if (farDistance <= 0.0)
        return -1.0;
    return nearDistance > 0.0 ? nearDistance : farDistance;
}

vec3 referenceFallbackTangent(vec3 normal)
{
    vec3 axis = abs(normal.z) < abs(normal.x) ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
    return normalize(cross(axis, normal));
}
#endif