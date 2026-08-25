# Research - MaterialX Pathtracer Host Generator

## Decision 1: Separate MTLX pathtracer route
- Decision: Create `glsl/pathtracing/mtlx/` and seed `pathtracer.glsl` from `glsl/pathtracing/legacy/pathtracer.glsl`.
- Rationale: The pathtracer control flow is valuable, but legacy BXDF implementation dependencies must remain isolated.
- Alternatives considered: Continue editing current production route (rejected because it mixes previous WASM-adapter work with the corrected generator goal).

## Decision 2: Generate dispatch artifacts only
- Decision: The C++ generator owns per-material `generated_bsdf_dispatch.glsl` artifacts containing `evaluateBsdf` and `sampleBsdf`; it does not generate the entire pathtracer file.
- Rationale: The copied pathtracer remains readable and stable while the generated portion is replaceable and testable.
- Alternatives considered: Generate the full pathtracer (rejected due to larger blast radius); single multi-material dispatch file (rejected due to weaker traceability).

## Decision 3: One dispatch artifact per `.mtlx`
- Decision: Generate one deterministic artifact per selected `.mtlx` material.
- Rationale: Each material has its own closure graph, helpers, diagnostics, and validation result.
- Alternatives considered: One file per model or one multi-material switch (rejected because material-specific generated code and errors become harder to isolate).

## Decision 4: All listed material models in first delivery
- Decision: First delivery supports `open_pbr_surface`, `standard_surface`, `disney_principled`, `gltf_pbr`, and `usd_preview_surface`.
- Rationale: The user selected full listed model coverage for the MVP.
- Alternatives considered: OpenPBR-only first delivery (rejected by clarification); OpenPBR + Standard Surface only (rejected by clarification).

## Decision 5: EsslHostShaderGenerator as primary model
- Decision: Design `MtlxPathTracerHostShaderGenerator` from host-generation responsibilities found in `EsslHostShaderGenerator`.
- Rationale: The desired output is host/integration dispatch GLSL, not only a closure-stage shader.
- Alternatives considered: Use `PathTracerGlslShaderGenerator` directly (rejected because it is explicitly unsuitable for this chantier).

## Decision 6: Explicit failure for incomplete closure support
- Decision: Fail generation when any closure lacks a complete evaluate/sample/pdf strategy.
- Rationale: Generic approximations can produce plausible but invalid images and would hide generator gaps.
- Alternatives considered: Lambert/cosine fallback or evaluate-only support (rejected by clarification).

## Decision 7: Mixed validation corpus
- Decision: Validate with five existing carpaint files plus one simple synthetic fixture for each required model.
- Rationale: Carpaint provides comparable real fixtures; synthetic materials isolate minimal model behavior.
- Alternatives considered: Carpaint-only validation (rejected by clarification); synthetic-only validation (rejected as too weak for real material graphs).

## Decision 8: Legacy dependency ban
- Decision: The MTLX route and generated dispatch artifacts must not depend on legacy `_brdf.glsl`, `_btdf.glsl`, or legacy OpenPBR lobe entrypoints.
- Rationale: This is the core correction from the prior misaligned chantier.
- Alternatives considered: Compatibility shims into legacy files (rejected because they violate the new architecture).
