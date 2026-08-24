///////////////////////////////////////////////////////////////////////////////
// Adapter layer: bridges the OpenPBR-viewer BSDF API to the MaterialX
// EvalMtlxClosure / SampleMtlxClosure entry points injected above.
// Must appear AFTER the injected generated GLSL block.
///////////////////////////////////////////////////////////////////////////////

// Build a minimal State from the current shading context.
State mtlx_make_state(in vec3 pW, in Basis basis, in float eta)
{
    State s;
    s.matID    = 0;
    s.eta      = eta;
    s.fhp      = pW;
    s.normal   = basis.nW;
    s.ffnormal = basis.nW;
    s.tangent  = basis.tW;
    s.bitangent = basis.bW;
    s.texCoord = vec2(0.0); // UV not yet wired from geometry
    return s;
}

int openpbr_contract_material_id()
{
    // Single-material default contract in current integration.
    return 0;
}

vec3 openpbr_eval_generated_closure(
    in int matID,
    in State state,
    in vec3 V,
    in vec3 N,
    in vec3 L,
    inout float pdf,
    inout int flags)
{
    if (matID == 0)
    {
        return EvalMtlxClosure(0, state, V, N, L, pdf, flags);
    }
    // No fallback to legacy BXDF path.
    flags = CLOSURE_FLAG_REFLECT;
    pdf = 1.0;
    return vec3(0.0);
}

vec3 openpbr_sample_generated_closure(
    in int matID,
    in State state,
    in vec3 V,
    in vec3 N,
    out vec3 L,
    out float pdf,
    out int flags)
{
    if (matID == 0)
    {
        return SampleMtlxClosure(0, state, V, N, L, pdf, flags);
    }
    // No fallback to legacy BXDF path.
    L = N;
    flags = CLOSURE_FLAG_REFLECT;
    pdf = 1.0;
    return vec3(0.0);
}

void openpbr_prepare(in vec3 pW, in Basis basis, in vec3 winputL, inout uint rndSeed)
{
    // Sync the stateful RNG used by SampleMtlxClosure's rand() calls.
    g_mtlxRandSeed = rndSeed;
    // Material params are globals — just (re)compute the summary.
    pt_InitMaterialSummary();
    // Write back so subsequent rand(rndSeed) calls in pathtracer.glsl remain consistent.
    rndSeed = g_mtlxRandSeed;
}

bool openpbr_is_opaque()
{
    // A material is opaque when it has no transmission and full opacity.
    return pt_mOpacity >= 1.0 && pt_mSpecTrans < 0.001;
}

bool openpbr_is_thinwalled()
{
    return pt_mThinWalled;
}

vec3 openpbr_bsdf_evaluate(in vec3 pW, in Basis basis, in vec3 winputL, in vec3 woutputL,
                            inout float pdf_woutputL)
{
    // winputL.z > 0: entering dielectric (1/IOR); < 0: exiting (IOR).
    float mat_eta = (winputL.z >= 0.0) ? (1.0 / max(pt_mIor, 1.0 + 1e-5)) : max(pt_mIor, 1.0);
    State state = mtlx_make_state(pW, basis, mat_eta);
    // Flip V to upper hemisphere for exit so the closure sees consistent geometry.
    bool exiting = (winputL.z < 0.0);
    vec3 V = localToWorld(exiting ? -winputL : winputL, basis);
    vec3 N = basis.nW;
    vec3 L = localToWorld(exiting ? -woutputL : woutputL, basis);
    int flags;
    int matID = openpbr_contract_material_id();
    return openpbr_eval_generated_closure(matID, state, V, N, L, pdf_woutputL, flags);
}

vec3 openpbr_bsdf_sample(in vec3 pW, in Basis basis, in vec3 winputL, inout uint rndSeed,
                          out vec3 woutputL, out float pdf_woutputL, out Volume internal_medium)
{
    // Sync stateful RNG so SampleMtlxClosure's rand() draws are seeded correctly.
    g_mtlxRandSeed = rndSeed;

    float mat_eta = (winputL.z >= 0.0) ? (1.0 / max(pt_mIor, 1.0 + 1e-5)) : max(pt_mIor, 1.0);
    State state = mtlx_make_state(pW, basis, mat_eta);
    // g_ptTangent / g_ptBitangent are read by some mx_* functions at sample time.
    g_ptTangent   = basis.tW;
    g_ptBitangent = basis.bW;

    // Flip V to upper hemisphere for exit so the closure sees consistent geometry.
    bool exiting = (winputL.z < 0.0);
    vec3 V = localToWorld(exiting ? -winputL : winputL, basis);
    vec3 N = basis.nW;
    vec3 L;
    int flags;
    int matID = openpbr_contract_material_id();
    vec3 f = openpbr_sample_generated_closure(matID, state, V, N, L, pdf_woutputL, flags);

    // For exit the closure returns L in the flipped frame; un-flip it.
    woutputL = worldToLocal(exiting ? -L : L, basis);

    // Write the advanced RNG state back.
    rndSeed = g_mtlxRandSeed;

    // Populate the volumetric medium for transmissive hits (Beer-Lambert glass).
    internal_medium.extinction = vec3(0.0);
    internal_medium.albedo     = vec3(0.0);
    internal_medium.anisotropy = 0.0;
#ifdef VOLUME_ENABLED
    if ((flags & CLOSURE_FLAG_TRANSMIT) != 0 && !pt_mThinWalled && transmission_depth > 0.0)
    {
        // transmission_color / transmission_depth are folded globals from __MTLX_PARAMS_BEGIN__.
        internal_medium.extinction = -log(max(vec3(1e-6), transmission_color)) / transmission_depth;
        internal_medium.albedo     = transmission_scatter;
        internal_medium.anisotropy = transmission_scatter_anisotropy;
    }
#endif
    return f;
}
