///////////////////////////////////////////////////////////////////////////////
// MTLX pathtracer dispatch hooks (feature 003).
//
// Provides the mtlx_openpbr_* hooks required by glsl/pathtracing/mtlx/pathtracer.glsl.
// The OpenPBR-material dispatch is wired to the MaterialX generated closure
// adapter (openpbr_bsdf_evaluate / openpbr_bsdf_sample from mtlx_adapters.glsl),
// which itself calls the injected EvalMtlxClosure / SampleMtlxClosure. This keeps
// the MTLX route free of legacy _brdf/_btdf lobe files while the C++ host
// generator (US2) takes over emitting these hooks per material.
//
// NOTE: this bridge is assembled AFTER the MaterialX generated GLSL and the
// mtlx_adapters block, so openpbr_bsdf_* below refer to the generated-closure
// adapters, not to any legacy lobe implementation.
///////////////////////////////////////////////////////////////////////////////

void mtlx_openpbr_prepare(in vec3 pW, in Basis basis, in vec3 winputL, inout uint rndSeed)
{
    openpbr_prepare(pW, basis, winputL, rndSeed);
}

bool mtlx_openpbr_is_opaque()
{
    return openpbr_is_opaque();
}

bool mtlx_openpbr_is_thinwalled()
{
    return openpbr_is_thinwalled();
}

vec3 mtlx_openpbr_bsdf_evaluate(in vec3 pW, in Basis basis, in vec3 winputL, in vec3 woutputL,
                                inout float pdf_woutputL)
{
    return openpbr_bsdf_evaluate(pW, basis, winputL, woutputL, pdf_woutputL);
}

vec3 mtlx_openpbr_bsdf_sample(in vec3 pW, in Basis basis, in vec3 winputL, inout uint rndSeed,
                              out vec3 woutputL, out float pdf_woutputL, out Volume internal_medium)
{
    return openpbr_bsdf_sample(pW, basis, winputL, rndSeed, woutputL, pdf_woutputL, internal_medium);
}
