# Research - MaterialX Pathtracer Host Generator

## Decision 1: New route instead of mutating legacy
- Decision: Create `glsl/pathtracing/mtlx/` as a separate route and seed it from `glsl/pathtracing/legacy/pathtracer.glsl`.
- Rationale: The pathtracer control flow can be reused while keeping legacy code available only for comparison.
- Alternatives considered: Continue editing the current `glsl/pathtracing/pathtracer.glsl` route (rejected because it mixes previous WASM-adapter work with the new generator goal).

## Decision 2: Generate dispatch, not legacy BXDF implementations
- Decision: The new C++ generator emits `evaluateBsdf` and `sampleBsdf` dispatch functions.
- Rationale: The user explicitly wants the dispatch methods generated from the selected `.mtlx` material model.
- Alternatives considered: Keep hand-written dispatch calling `openpbr_bsdf_evaluate` and `openpbr_bsdf_sample` (rejected because it remains OpenPBR legacy-specific).

## Decision 3: Use EsslHostShaderGenerator as primary model
- Decision: Base design and tasking on a new `MtlxPathTracerHostShaderGenerator` inspired by `EsslHostShaderGenerator`.
- Rationale: The desired output is host/integration GLSL, not only a closure-stage generator.
- Alternatives considered: Use `PathTracerGlslShaderGenerator` directly (rejected because the user identified it as unsuitable for this chantier).

## Decision 4: Allow limited adapted reuse from PathTracerGlslShaderGenerator
- Decision: Permit deliberate copy/adaptation of small helper concepts only when documented in the new generator.
- Rationale: Some state/closure wiring ideas may be useful, but ownership must move to the new generator.
- Alternatives considered: Ban all reference to prior pathtracer generator code (rejected because it could discard useful context unnecessarily).

## Decision 5: MaterialX-generated closures are authoritative
- Decision: Generated dispatch must call MaterialX-generated EDF/BSDF/BRDF/BTDF/helper functions and not legacy `_brdf.glsl` or `_btdf.glsl` files.
- Rationale: This is the core correction from the previous chantier.
- Alternatives considered: Use legacy lobe files as compatibility shims (rejected because it violates the request and hides generator gaps).

## Decision 6: First validation material
- Decision: Use `D:\WebGL2\MaterialX\materials\open_pbr_carpaint.mtlx` as the first validation case.
- Rationale: The user named this material set, and it provides a concrete proof target.
- Alternatives considered: Validate only a synthetic default material (rejected as too weak for proving material-model dispatch).

## Decision 7: Explicit failure semantics
- Decision: Unsupported material models, missing closure symbols, missing generated dispatch, or incompatible signatures fail explicitly.
- Rationale: Aligns with the project constitution and avoids silent legacy fallback.
- Alternatives considered: Fallback to legacy OpenPBR dispatch (rejected by constitution and user request).
