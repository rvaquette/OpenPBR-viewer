
#include <envmap_common_pars_fragment>

//////////////////////////////////////////////////////
// camera uniforms
//////////////////////////////////////////////////////

uniform mat4 cameraWorldMatrix;
uniform mat4 invProjectionMatrix;
uniform mat4 invModelMatrix;
uniform vec2 resolution;

//////////////////////////////////////////////////////
// geometry uniforms
//////////////////////////////////////////////////////

uniform BVH bvh_surface;

// Packed per-vertex attributes, kept under MAX_TEXTURE_IMAGE_UNITS(16):
//   geomN_surface = vec4(normal.xyz, uv.x)
//   geomT_surface = vec4(tangent.xyz, uv.y)
//   geomS_surface = vec4(materialSlot, 0, 0, 0)
uniform sampler2D geomN_surface;
uniform sampler2D geomT_surface;
uniform sampler2D geomS_surface;
uniform bool has_normals_surface;
uniform bool has_tangents_surface;
uniform bool has_uvs_surface;

uniform sampler2D ground_texture;

//////////////////////////////////////////////////////
// renderer uniforms
//////////////////////////////////////////////////////

uniform float accumulation_weight;
uniform float samples;
uniform bool wireframe;
uniform bool debug_material_slots;
uniform vec3 neutral_color;
uniform bool smooth_normals;
uniform int bounces;
uniform int max_volume_steps;
uniform float firefly_clamp;
uniform bool strict_failure_enabled;
uniform bool generated_contract_valid;
uniform int generated_contract_failure_code;

//////////////////////////////////////////////////////
// lighting uniforms
//////////////////////////////////////////////////////

uniform float skyPower;
uniform vec3 skyColor;

uniform float sunPower;
uniform float sunAngularSize;
uniform vec3 sunColor;
uniform vec3 sunDir;
uniform bool mtlxDisableSun;

uniform int mtlxLightCount;
uniform int mtlxLightType[MAX_MTLX_LIGHTS];
uniform vec3 mtlxLightPosition[MAX_MTLX_LIGHTS];
uniform vec3 mtlxLightDirection[MAX_MTLX_LIGHTS];
uniform vec3 mtlxLightColor[MAX_MTLX_LIGHTS];
uniform float mtlxLightIntensity[MAX_MTLX_LIGHTS];
uniform float mtlxLightDecayRate[MAX_MTLX_LIGHTS];
uniform float mtlxLightInnerCone[MAX_MTLX_LIGHTS];
uniform float mtlxLightOuterCone[MAX_MTLX_LIGHTS];

//////////////////////////////////////////////////////
// UVs
//////////////////////////////////////////////////////
varying vec2 vUv;

//////////////////////////////////////////////////////
// useful constants
//////////////////////////////////////////////////////

const float PI                    = 3.141592653589793;
const float PI2                   = 6.283185307179586;
const float HUGE_DIST             = 1.0e20;
const float RAY_OFFSET            = 1.0e-4;
const float DENOM_TOLERANCE       = 1.0e-10;

const int MATERIAL_PROPS   = 0;
const int MATERIAL_OPENPBR = 1;
const int MATERIAL_GROUND  = 2;

bool strictGeneratedContractFailure()
{
    return strict_failure_enabled && !generated_contract_valid;
}

vec3 safe_normalize(in vec3 N)
{
    float l = length(N);
    return N/max(l, DENOM_TOLERANCE);
}

float minComponent(in vec3 v)
{
    return min(v.x, min(v.y, v.z));
}

struct Basis
{
    vec3 nW;
    vec3 tW;
    vec3 bW;
    vec3 baryCoord;
    vec2 texCoord;
    int materialSlot;
};

vec3 normalToTangent(in vec3 N)
{
    vec3 T;
    if (abs(N.z) < abs(N.x))
        T = vec3(N.z, 0.0, -N.x);
    else
        T = vec3(0.0, N.z, -N.y);
    T = safe_normalize(T);
    return T;
}

Basis makeBasis(in vec3 nW)
{
    Basis basis;
    basis.nW = safe_normalize(nW);
    basis.tW = normalToTangent(nW);
    basis.bW = cross(basis.nW, basis.tW);
    basis.baryCoord = vec3(0.0);
    basis.texCoord = vec2(0.0);
    basis.materialSlot = 0;
    return basis;
}

Basis makeBasis(in vec3 nW, in vec3 tW, in vec3 baryCoord, in vec2 texCoord, in int materialSlot)
{
    Basis basis;
    basis.nW = safe_normalize(nW);
    basis.tW = safe_normalize(tW);
    basis.bW = cross(basis.nW, basis.tW);
    basis.baryCoord = baryCoord;
    basis.texCoord = texCoord;
    basis.materialSlot = materialSlot;
    return basis;
}

Basis makeBasis(in vec3 nW, in vec3 tW, in vec3 bW, in vec3 baryCoord, in vec2 texCoord, in int materialSlot)
{
    Basis basis;
    basis.nW = safe_normalize(nW);
    basis.tW = safe_normalize(tW);
    basis.bW = safe_normalize(bW);
    basis.baryCoord = baryCoord;
    basis.texCoord = texCoord;
    basis.materialSlot = materialSlot;
    return basis;
}

vec3 worldToLocal(in vec3 vWorld, in Basis basis)
{
    return vec3( dot(vWorld, basis.tW),
                 dot(vWorld, basis.bW),
                 dot(vWorld, basis.nW) );
}

vec3 localToWorld(in vec3 vLocal, in Basis basis)
{
    return basis.tW*vLocal.x + basis.bW*vLocal.y + basis.nW*vLocal.z;
}

bool bvhIntersectFirstHitWithinDistance(
    BVH bvh, vec3 rayOrigin, vec3 rayDirection, in float maxDistance,
    inout uvec4 faceIndices, inout vec3 faceNormal, inout vec3 barycoord,
    inout float side, inout float dist)
{
    int ptr = 0;
    uint stack[32];
    stack[0] = 0u;
    float triangleDistance = HUGE_DIST;
    bool found = false;
    while (ptr > -1 && ptr < 32)
    {
        uint currNodeIndex = stack[ptr];
        ptr--;
        float boundsHitDistance = intersectsBVHNodeBounds(rayOrigin, rayDirection, bvh, currNodeIndex);
        if (boundsHitDistance == INFINITY ||
            boundsHitDistance > triangleDistance ||
            boundsHitDistance > maxDistance)
            continue;
        uvec2 boundsInfo = uTexelFetch1D(bvh.bvhContents, currNodeIndex).xy;
        bool isLeaf = bool(boundsInfo.x & 0xffff0000u);
        if (isLeaf)
        {
            uint count = boundsInfo.x & 0x0000ffffu;
            uint offset = boundsInfo.y;
            float minDistance = min(maxDistance, triangleDistance);
            bool foundIntersection = intersectTriangles(bvh, rayOrigin, rayDirection, offset, count, minDistance,
                                                        faceIndices, faceNormal, barycoord, side, dist);
            if (foundIntersection)
            {
                triangleDistance = minDistance;
                found = true;
            }
        }
        else
        {
            uint leftIndex = currNodeIndex + 1u;
            uint splitAxis = boundsInfo.x & 0x0000ffffu;
            uint rightIndex = boundsInfo.y;
            bool leftToRight = rayDirection[splitAxis] >= 0.0;
            uint c1 = leftToRight ? leftIndex : rightIndex;
            uint c2 = leftToRight ? rightIndex : leftIndex;
            ptr++;
            stack[ptr] = c2;
            ptr++;
            stack[ptr] = c1;
        }
    }
    return found;
}

bool trace(in vec3 rayOrigin, in vec3 rayDir, in float maxDistance,
           out vec3 P, out vec3 Ns, out vec3 Ng, out vec3 Ts, out vec3 Bs, out vec3 baryCoord, out vec2 texCoord, out int materialSlot, out int material)
{
    uvec4 faceIndices_surface = uvec4(0u);
    vec3 faceNormal_surface = vec3(0.0, 0.0, 1.0);
    vec3 barycoord_surface = vec3(0.0);
    float side_surface = 1.0;
    float dist_surface = HUGE_DIST;
    bool hit_surface = bvhIntersectFirstHitWithinDistance(bvh_surface, rayOrigin, rayDir, maxDistance,
                                                          faceIndices_surface, faceNormal_surface, barycoord_surface, side_surface, dist_surface);
    float dist_closest = HUGE_DIST;
    if (hit_surface) dist_closest = min(dist_closest, dist_surface);

    const float GROUND_Y = 0.01;
    float dist_ground = HUGE_DIST;
    bool hit_ground = false;
    if (abs(rayDir.y) > DENOM_TOLERANCE)
    {
        float t = (GROUND_Y - rayOrigin.y) / rayDir.y;
        if (t > 0.0 && t < min(dist_closest, maxDistance))
        {
            dist_ground = t;
            hit_ground = true;
        }
    }

    bool hit = hit_surface || hit_ground;
    if (!hit) return false;

    if (hit_surface && (!hit_ground || (dist_surface <= dist_ground)))
    {
        P = rayOrigin + dist_surface*rayDir;
        baryCoord = barycoord_surface;
        Ng = safe_normalize(faceNormal_surface);
        vec4 gN = textureSampleBarycoord(geomN_surface, barycoord_surface, faceIndices_surface.xyz);
        vec4 gT = textureSampleBarycoord(geomT_surface, barycoord_surface, faceIndices_surface.xyz);
        vec4 gS = textureSampleBarycoord(geomS_surface, barycoord_surface, faceIndices_surface.xyz);
        Ns = has_normals_surface ? gN.xyz : Ng;
        texCoord = has_uvs_surface ? vec2(gN.w, gT.w) : barycoord_surface.xy;
        Ts = has_tangents_surface ? gT.xyz : normalToTangent(Ns);
        Bs = cross(safe_normalize(Ns), safe_normalize(Ts));
        materialSlot = int(floor(gS.x + 0.5));
        material = (gS.y > 0.5) ? MATERIAL_PROPS : MATERIAL_OPENPBR;   // neutral objects merged into surface BVH
    }
    else if (hit_ground)
    {
        P = rayOrigin + dist_ground*rayDir;
        material = MATERIAL_GROUND;
        baryCoord = vec3(0.0);
        Ng = vec3(0.0, 1.0, 0.0);
        Ns = Ng;
        Ts = vec3(1.0, 0.0, 0.0);
        Bs = vec3(0.0, 0.0, -1.0);
        texCoord = vec2(P.x, -P.z) / 200.0 * 2.0 + 0.5;
        materialSlot = 0;
    }
    return true;
}

vec3 ground_albedo(in vec3 pW)
{
    vec2 uv = vec2(pW.x, -pW.z) / 200.0 * 2.0 + 0.5;
    return texture(ground_texture, uv).rgb;
}

Basis sunBasis;

vec3 sunRadiance(in vec3 woutputW)
{
    float theta_max = sunAngularSize * PI/180.0;
    if (dot(woutputW, sunDir) < cos(theta_max)) return vec3(0.0);
    return sunPower * sunColor;
}

vec3 skyRadiance(in vec3 woutputW)
{
    vec4 env = textureLod(envMap, vec3(woutputW.x, woutputW.yz), 0.0);
    return env.rgb * skyPower * skyColor;
}