# MTLX Pathtracer Generator Contract

## Purpose
Define the C++ generator contract for emitting per-material pathtracer host dispatch GLSL from selected MaterialX material graphs.

## Producer
`../MaterialX-rva/source/MaterialXGenGlsl/MtlxPathTracerHostShaderGenerator.*`

## Primary Reference
`../MaterialX-rva/source/MaterialXGenGlsl/EsslHostShaderGenerator.*`

## Explicit Non-Dependency
`PathTracerGlslShaderGenerator` must not be used as the implementation generator for this chantier. Limited copied/adapted helper concepts are allowed only when moved into the new generator and documented.

## Required Material Models
The first delivery must support the following authoritative MaterialX node
categories (as read from the `.mtlx` surface node):
- `open_pbr_surface`
- `standard_surface`
- `disney_principled`
- `gltf_pbr`
- `UsdPreviewSurface`

Note: the spec identifier `usd_preview_surface` maps to the authoritative
MaterialX node category `UsdPreviewSurface` (CamelCase). The generator resolves
the model from the node category, so the CamelCase form is canonical in code.

## Required Generated Artifact
For each selected `.mtlx` material, the generator must emit one deterministic dispatch artifact:

```text
glsl/pathtracing/mtlx/generated/<material-id>/generated_bsdf_dispatch.glsl
```

Each artifact must define:

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
Generated dispatch and the MTLX route must not depend on:
- `glsl/pathtracing/legacy/*_brdf.glsl`
- `glsl/pathtracing/legacy/*_btdf.glsl`
- legacy OpenPBR-only lobe dispatch as the production implementation

## Failure Rules
- Unsupported material models fail explicitly.
- Missing generated closure functions fail explicitly.
- Signature mismatch fails explicitly.
- Incomplete evaluate/sample/pdf strategy fails explicitly.
- No generic approximation is allowed.
- No fallback to legacy BXDF implementation files is allowed.

## Validation Corpus
The generator must produce artifacts for every fixture listed in `validation-corpus-contract.md`.
