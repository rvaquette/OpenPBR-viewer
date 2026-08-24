# MTLX Viewer Route Contract

## Purpose
Define how the viewer consumes generated MaterialX pathtracer host dispatch GLSL.

## Route
`glsl/pathtracing/mtlx/`

## Required Files
- `glsl/pathtracing/mtlx/pathtracer.glsl`
- `glsl/pathtracing/mtlx/generated_bsdf_dispatch.glsl`

## Assembly Rules
1. The MTLX route must be assembled separately from `glsl/pathtracing/legacy/`.
2. The MTLX route may reuse shared host primitives such as BVH traversal, basis transforms, random sampling utilities, environment lighting, and volume structs.
3. The MTLX route must receive `evaluateBsdf` and `sampleBsdf` from generated dispatch output.
4. The MTLX route must not include legacy `_brdf.glsl` or `_btdf.glsl` files.

## Validation Rules
- Build must succeed with `npm run build`.
- Generated dispatch must pass text checks for required function definitions.
- Generated dispatch must pass text checks for absence of legacy BXDF references.
- First viewer validation target is `D:\WebGL2\MaterialX\materials\open_pbr_carpaint.mtlx`.

## Failure Rules
- If generated dispatch is missing, fail route assembly explicitly.
- If generated dispatch references forbidden legacy files/functions, fail validation explicitly.
- If shader compile fails, record the GLSL driver log and do not fallback to legacy mode.
