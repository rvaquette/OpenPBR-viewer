# Implementation Plan: WASM BXDF Replacement

**Branch**: `002-le-code-wasm` | **Date**: 2026-08-23 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from /specs/002-wasm-bxdf-replacement/spec.md

## Summary

Replace legacy hand-written BXDF usage in the pathtracer main flow with MaterialX WASM generated shading functions, enforce strict no-fallback behavior on missing/incompatible generated functions, and validate substitution outcomes through structured per-material reporting and manual legacy comparison workflow. The scope explicitly includes C++ updates in PathTracerGlslShaderGenerator so generated GLSL is conformant with legacy pathtracing expectations.

## Technical Context

**Language/Version**: JavaScript (ES modules, Node.js runtime), GLSL (WebGL shaders), C++ (MaterialX generator side)

**Primary Dependencies**: three, three-mesh-bvh, vite, playwright-core, sharp, MaterialX WASM integration, MaterialXGenGlsl PathTracerGlslShaderGenerator

**Storage**: File-based assets, generated GLSL snippets, and JSON report artifacts

**Testing**: Headless render validation via launch_render.mjs, generator-output ABI conformance checks, substitution report schema validation, manual legacy comparison runs

**Target Platform**: Browser WebGL viewer + Node.js tooling + C++/WASM generator toolchain

**Project Type**: Single-page WebGL application with cross-repo shader-generation integration

**Performance Goals**: Preserve interactive viewer behavior and keep integration readiness under 15 minutes for 90% of validation runs

**Constraints**: Strict per-material failure on missing/incompatible generated functions, no production fallback to legacy BXDF, legacy comparison manual-only, generated GLSL ABI must match legacy integration contract

**Scale/Scope**: Substitution on prioritized material corpus plus C++ generator conformance updates in MaterialX-rva for PathTracerGlslShaderGenerator outputs

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Status: PASS
- Observation: Constitution is now operational and defines generated-shading authority, explicit contracts, cross-repo discipline, and release gates.
- Decision: Proceed under constitutional constraints and enforce contract/diagnostic requirements during implementation.

Post-Phase 1 Re-check:
- Research/design artifacts include strict failure policy, manual comparison boundary, report schema completeness, and C++ ABI conformance coverage.
- No constitutional blockers identified.

## Project Structure

### Documentation (this feature)

```text
specs/002-wasm-bxdf-replacement/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── generated-shading-contract.md
│   ├── generator-abi-contract.md
│   └── substitution-report.schema.json
└── tasks.md
```

### Source Code (repository root)

```text
main.js
launch_render.mjs

glsl/
├── pathtracing/
│   ├── main.glsl
│   ├── mtlx_host.glsl
│   ├── mtlx_adapters.glsl
│   ├── pathtracer.glsl
│   └── legacy/
└── rasterization/

public/
└── mtlx/
```

### External Generator Repository (cross-repo dependency)

```text
../MaterialX-rva/
├── source/MaterialXGenGlsl/
│   └── PathTracerGlslShaderGenerator (C++ implementation)
└── javascript/
    └── WASM generation scripts
```

**Structure Decision**: Keep existing viewer layout and integrate generated shading through current pathtracing boundary while adding C++ generator conformance changes in the external MaterialX-rva repository.

## Phase Plan

### Phase 0 - Research and Contract Decisions
- Lock strict-failure and no-fallback behavior.
- Define generator-to-legacy ABI mapping (entry points, signatures, helper dependencies).
- Confirm manual-only comparison policy and release-critical criteria.

### Phase 1 - Design and Contracts
- Maintain data entities and transitions in data-model.md.
- Maintain runtime rules in contracts/generated-shading-contract.md.
- Add ABI conformance rules in contracts/generator-abi-contract.md.
- Keep substitution report schema in contracts/substitution-report.schema.json.
- Update quickstart with C++ generator regeneration and verification flow.

### Phase 2 - Implementation Planning Readiness
- Decompose into executable tasks for:
  - viewer-side runtime and shader integration changes
  - C++ PathTracerGlslShaderGenerator conformance updates
  - WASM regeneration and artifact propagation
  - strict failure diagnostics and report generation
  - validation workflow and release gating

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | N/A | N/A |
