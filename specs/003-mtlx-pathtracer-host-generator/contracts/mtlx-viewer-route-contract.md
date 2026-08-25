# MTLX Viewer Route Contract

## Purpose
Define how the viewer consumes generated MaterialX pathtracer host dispatch GLSL.

## Route
`glsl/pathtracing/mtlx/`

## Required Files
- `glsl/pathtracing/mtlx/pathtracer.glsl`
- `glsl/pathtracing/mtlx/generated/<material-id>/generated_bsdf_dispatch.glsl`

## Assembly Rules
1. The MTLX route must be assembled separately from `glsl/pathtracing/legacy/`.
2. The MTLX route may reuse shared host primitives such as BVH traversal, basis transforms, random sampling utilities, environment lighting, and volume structs.
3. The MTLX route must receive `evaluateBsdf` and `sampleBsdf` from exactly one generated dispatch artifact selected for the active `.mtlx` material.
4. The MTLX route must not include legacy `_brdf.glsl` or `_btdf.glsl` files.
5. The route must fail explicitly when the expected generated dispatch artifact is absent.

## Validation Rules
- Build must succeed with `npm run build`.
- Every generated dispatch artifact must pass text checks for required function definitions.
- Every generated dispatch artifact must pass text checks for absence of legacy BXDF references.
- Headless compile/render validation must run for all fixtures listed in `validation-corpus-contract.md`.

## Failure Rules
- If generated dispatch is missing, fail route assembly explicitly.
- If generated dispatch references forbidden legacy files/functions, fail validation explicitly.
- If shader compile fails, record the GLSL driver log and do not fallback to legacy mode.
