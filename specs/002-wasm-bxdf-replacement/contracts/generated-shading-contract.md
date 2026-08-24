# Generated Shading Integration Contract

## Purpose
Define the runtime contract between MaterialX WASM generated shading output and the pathtracer substitution layer.

## Contract Scope
- Consumer: pathtracer integration layer in OpenPBR viewer.
- Producer: MaterialX WASM shading generator output.
- Applies per material; no universal mandatory function set.

## Required Contract Fields (Per Material)
- `materialId`
- `wasmGenerationVersion`
- `requiredFunctions[]`
- `optionalFunctions[]`

## Runtime Rules
1. The pathtracer must bind and call only generated functions listed by the material contract.
2. If any required generated function is missing or signature-incompatible, rendering for that material fails explicitly.
3. No automatic fallback to legacy `XXX_bXdf.glsl` functions is allowed in production path.
4. Legacy comparison is manual-only and outside automated production pipeline.
5. Contract validation must run before shader compile and before first render.

## Signature Compatibility
- Function names and parameter signatures must match the integration layer expectations.
- Signature mismatch is treated as contract incompatibility (explicit failure).

## Diagnostics Requirements
Per material failure diagnostics must include:
- missing/incompatible function name
- validation step where failure was detected
- `wasmGenerationVersion`

## Version Propagation
- `wasmGenerationVersion` must be attached to runtime state and report artifacts.
- ABI checks and substitution runs must emit the same generator version for traceability.

## Validation Outputs
Each material emits a substitution report entry matching `contracts/substitution-report.schema.json`.
