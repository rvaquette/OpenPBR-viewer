# Generator ABI Contract

## Purpose
Define the ABI compatibility requirements between C++ PathTracerGlslShaderGenerator output and the legacy GLSL pathtracing integration expected by the viewer.

## Scope
- Producer: MaterialX C++ PathTracerGlslShaderGenerator in MaterialXGenGlsl.
- Consumer: Viewer pathtracing integration layer and adapters in this repository.
- Applies to each generator version used to produce WASM shading artifacts.

## Required Conformance
1. Generated entrypoint names must match the expected legacy integration symbol map.
2. Generated function signatures must match required argument and return conventions expected by the pathtracer.
3. Required helper functions used by pathtracing integration must be present when referenced by generated entrypoints.
4. Any symbol/signature mismatch is non-conformant and treated as explicit material failure path.

## Versioning
- Every generated artifact set must carry a generator version identifier.
- ABI changes require updating contract version notes and integration validation rules before rollout.

## Validation Checklist
- Entry points present and resolvable.
- Signature compatibility pass.
- Helper dependency compatibility pass.
- Conformance flag recorded for each generated build.

## Relationship to Runtime Rules
- No production fallback to legacy BXDF modules when ABI is non-conformant.
- Manual legacy comparison remains a validation-only workflow.
