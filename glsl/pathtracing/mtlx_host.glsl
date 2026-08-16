///////////////////////////////////////////////////////////////////////////////
// Host stubs required by PathTracerGlslShaderGenerator-generated closures.
// Must appear BEFORE the injected generated GLSL block.
///////////////////////////////////////////////////////////////////////////////

// Raw equirectangular env map used by MaterialX IBL functions (u_envRadiance / u_envIrradiance).
uniform sampler2D envMapLatLong;

// Closure direction flags (mirror GLSL-PathTracer-JS common/globals.glsl).
#define CLOSURE_FLAG_REFLECT  1
#define CLOSURE_FLAG_TRANSMIT 2
#define CLOSURE_FLAG_EMISSIVE 4

#define INV_PI 0.31830988618379067

// Minimal State struct: only fields accessed by EvalMtlxClosure / SampleMtlxClosure.
struct State
{
    int   matID;
    float eta;
    vec3  fhp;
    vec3  normal;
    vec3  ffnormal;
    vec3  tangent;
    vec3  bitangent;
    vec2  texCoord;
};

// Stateful parameterless RNG used by SampleMtlxClosure internally.
// The adapter sets g_mtlxRandSeed from rndSeed before each call.
uint g_mtlxRandSeed;

float rand()
{
    g_mtlxRandSeed ^= g_mtlxRandSeed << 13u;
    g_mtlxRandSeed ^= g_mtlxRandSeed >> 17u;
    g_mtlxRandSeed ^= g_mtlxRandSeed << 5u;
    return float(g_mtlxRandSeed) * 2.3283064365386963e-10;
}

// Build an orthonormal tangent frame from a normal.
void Onb(vec3 N, out vec3 T, out vec3 B)
{
    T = normalToTangent(N);
    B = cross(N, T);
}

// Isotropic GGX microfacet NDF (GTR2 is the standard PBRT name for GGX).
float GTR2(float cosTheta, float alpha)
{
    float a2 = alpha * alpha;
    float d = cosTheta * cosTheta * (a2 - 1.0) + 1.0;
    return a2 / max(PI * d * d, DENOM_TOLERANCE);
}

// Isotropic GGX height-correlated single-scattering masking term.
float SmithG(float cosTheta, float alpha)
{
    float a2 = alpha * alpha;
    float ct = abs(cosTheta);
    return 2.0 * ct / max(ct + sqrt(a2 + (1.0 - a2) * cosTheta * cosTheta), DENOM_TOLERANCE);
}

// GGX Visible Normal Distribution Function sampling (Dupuy & Jakob HPG 2023).
// Returns the sampled microfacet normal in local space (z = macro-normal).
vec3 SampleGGXVNDF(vec3 Vl, float ax, float ay, float r1, float r2)
{
    vec3 V = normalize(vec3(Vl.xy * vec2(ax, ay), Vl.z));
    float phi = 2.0 * PI * r1;
    float z   = (1.0 - r2) * (1.0 + V.z) - V.z;
    float st  = sqrt(clamp(1.0 - z * z, 0.0, 1.0));
    vec3  c   = vec3(st * cos(phi), st * sin(phi), z);
    vec3  H   = c + V;
    return normalize(vec3(H.xy * vec2(ax, ay), H.z));
}

// Cosine-weighted hemisphere sampling (r1 = azimuth rand, r2 = elevation rand).
vec3 CosineSampleHemisphere(float r1, float r2)
{
    float phi = 2.0 * PI * r1;
    float st  = sqrt(r2);
    return vec3(st * cos(phi), st * sin(phi), sqrt(max(0.0, 1.0 - r2)));
}

// Dielectric Fresnel (scalar) — alias for the host's existing function.
float DielectricFresnel(float cosTheta, float eta)
{
    return FresnelDielectricReflectance(cosTheta, eta);
}

// No-op for single-material scenes: params are folded as globals by the generator.
void mtlxLoadParams(int matID) {}
