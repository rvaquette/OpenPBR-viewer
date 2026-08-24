# Phase 0 Research - WASM BXDF Replacement

## Decision 1: Integration Boundary for Generated Shading
- Decision: Treat MaterialX WASM output as the single source for shading functions used by the pathtracer main flow.
- Rationale: Removes duplicated behavior between generated shading and legacy hand-written BXDF modules.
- Alternatives considered: Keep dual execution paths (rejected due to drift risk and debugging complexity).

## Decision 2: Per-Material Function Contract
- Decision: Use a per-material contract declaring which generated functions are required, without enforcing a universal BSDF/EDF/BRDF set.
- Rationale: Some materials legitimately require only a subset of generated functions.
- Alternatives considered: Universal mandatory set for all materials (rejected because it over-constrains valid material graphs).

## Decision 3: Missing/Incompatible Generated Function Handling
- Decision: Enforce strict per-material failure with explicit diagnostics; no automatic fallback to legacy modules.
- Rationale: Guarantees deterministic behavior and prevents silent production divergence.
- Alternatives considered: Automatic fallback to legacy (rejected due to hidden regressions).

## Decision 4: Legacy Comparison Policy
- Decision: Keep legacy comparison manual and outside automated production pipeline.
- Rationale: Supports forensic validation while preserving strict production behavior.
- Alternatives considered: Always-on automated comparison (rejected due to complexity and accidental coupling).

## Decision 5: Validation Report Contract
- Decision: Require substitution report fields: status, generated functions used, failure cause, visual-difference type, render time, WASM generation version.
- Rationale: Ensures actionable diagnostics and reproducibility across runs.
- Alternatives considered: Minimal status-only report (rejected as insufficient for release decisions).

## Decision 6: Critical Visual Difference Criteria
- Decision: Classify visual differences as critical when they show major divergence in global energy, dominant hue, or primary detail retention on material region.
- Rationale: Provides explicit, reviewable release gates tied to observable outcomes.
- Alternatives considered: Ad-hoc reviewer-only criticality decisions (rejected due to inconsistency).

## Decision 7: Migration Rollout Strategy
- Decision: Introduce generated-shading substitution through an isolated pathtracer integration layer and deprecate legacy BXDF usage in the main flow.
- Rationale: Enables controlled cutover with clear ownership and rollback boundaries.
- Alternatives considered: Big-bang rewrite of all legacy shaders at once (rejected due to integration risk).

## Decision 8: C++ Generator Conformance Updates
- Decision: Update PathTracerGlslShaderGenerator in MaterialX C++ code so generated GLSL conforms to legacy pathtracing expectations (entrypoint names, signatures, helper layout).
- Rationale: Viewer-side adapter complexity and fragility are reduced when generator outputs match expected ABI directly.
- Alternatives considered: Handle all compatibility via viewer-side GLSL adapters only (rejected due to long-term maintenance cost).

## Decision 9: ABI Contract as First-Class Artifact
- Decision: Define a documented ABI contract between C++ generator output and pathtracing legacy integration before implementation.
- Rationale: Prevents silent drift during future generator changes and enables explicit conformance checks.
- Alternatives considered: Implicit contract inferred from current shaders (rejected due to ambiguity).
