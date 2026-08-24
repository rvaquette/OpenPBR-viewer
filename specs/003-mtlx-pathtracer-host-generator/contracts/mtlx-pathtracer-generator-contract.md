# MTLX Pathtracer Generator Contract

## Purpose
Define the C++ generator contract for emitting pathtracer host dispatch GLSL from selected MaterialX material graphs.

## Producer
`../MaterialX-rva/source/MaterialXGenGlsl/MtlxPathTracerHostShaderGenerator.*`

## Primary Reference
`../MaterialX-rva/source/MaterialXGenGlsl/EsslHostShaderGenerator.*`

## Explicit Non-Dependency
`PathTracerGlslShaderGenerator` must not be used as the implementation generator for this chantier. Limited copied/adapted helper concepts are allowed only when moved into the new generator and documented.

## Required Generated GLSL
The generator must emit:

```glsl
vec3 evaluateBsdf(in vec3 pW, in Basis basis, in vec3 winputL, in vec3 woutputL, in int material,
                  inout float pdf_woutputL)

vec3 sampleBsdf(in vec3 pW, in Basis basis, in vec3 winputL, inout uint rndSeed, in int material,
                out vec3 woutputL, out float pdf_woutputL, out Volume internal_medium)
```

## MaterialX Closure Sources
Generated dispatch must consume MaterialX-generated closure/helper functions for the selected `.mtlx` material model:
- EDF
- BSDF
- BRDF
- BTDF

## Forbidden References
Generated dispatch and MTLX route must not depend on:
- `glsl/pathtracing/legacy/*_brdf.glsl`
- `glsl/pathtracing/legacy/*_btdf.glsl`
- legacy OpenPBR-only lobe dispatch as the production implementation

## Failure Rules
- Unsupported material models fail explicitly.
- Missing generated closure functions fail explicitly.
- Signature mismatch fails explicitly.
- No fallback to legacy BXDF implementation files is allowed.

## First Required Fixture
`D:\WebGL2\MaterialX\materials\open_pbr_carpaint.mtlx`
