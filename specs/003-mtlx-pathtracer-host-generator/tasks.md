# Tasks: MaterialX Pathtracer Host Generator

**Input**: Design documents from `/specs/003-mtlx-pathtracer-host-generator/`

**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/, quickstart.md

**Tests**: Validation tasks are executable build, generation, text-check, and headless compile/render checks.

**Organization**: Tasks are grouped by user story for independent delivery and validation.

**Clarified scope**: First delivery supports `open_pbr_surface`, `standard_surface`, `disney_principled`, `gltf_pbr`, `usd_preview_surface`. The C++ generator emits one separate `generated_bsdf_dispatch.glsl` per `.mtlx`. Validation uses a mixed corpus (5 carpaint + 5 synthetic). Unsupported closures or incomplete evaluate/sample/pdf strategies fail explicitly with no approximation and no legacy fallback.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish the new route and generator scaffold without changing the legacy comparison path.

- [ ] T001 Create `glsl/pathtracing/mtlx/` and `glsl/pathtracing/mtlx/generated/` directories
- [ ] T002 Copy `glsl/pathtracing/legacy/pathtracer.glsl` to `glsl/pathtracing/mtlx/pathtracer.glsl` as the initial base
- [ ] T003 [P] Create artifact directories `artifacts/mtlx-pathtracer/fixtures/`, `artifacts/mtlx-pathtracer/generated/`, `artifacts/mtlx-pathtracer/validation/`
- [ ] T004 [P] Create generator wrapper scaffold `tools/generate-mtlx-pathtracer-dispatch.mjs`
- [ ] T005 [P] Create validation runner scaffold `tools/validate-mtlx-pathtracer-corpus.mjs`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Add cross-repo C++ generator scaffolding, deterministic artifact naming, and enforceable guards before viewer integration.

**CRITICAL**: No user story implementation starts before this phase is complete.

- [ ] T006 Create C++ header `../MaterialX-rva/source/MaterialXGenGlsl/MtlxPathTracerHostShaderGenerator.h`
- [ ] T007 Create C++ implementation `../MaterialX-rva/source/MaterialXGenGlsl/MtlxPathTracerHostShaderGenerator.cpp`
- [ ] T008 [P] Document `EsslHostShaderGenerator`-inspired responsibilities inside `MtlxPathTracerHostShaderGenerator.h`
- [ ] T009 [P] Add explicit non-dependency guard against `PathTracerGlslShaderGenerator` in `MtlxPathTracerHostShaderGenerator.cpp`
- [ ] T010 Register the new generator in the MaterialXGenGlsl build/source registry files under `../MaterialX-rva/source/MaterialXGenGlsl/`
- [ ] T011 Update WASM generation exposure for the new generator in `../MaterialX-rva/javascript/`
- [ ] T012 Implement deterministic per-material dispatch path resolver (material-id -> `glsl/pathtracing/mtlx/generated/<material-id>/generated_bsdf_dispatch.glsl`) in `tools/generate-mtlx-pathtracer-dispatch.mjs`
- [ ] T013 [P] Implement forbidden-dependency text-check (`legacy/`, `_brdf`, `_btdf`, `openpbr_bsdf_evaluate`, `openpbr_bsdf_sample`, `PathTracerGlslShaderGenerator`) in `tools/validate-mtlx-pathtracer-corpus.mjs`
- [ ] T014 [P] Define the mixed validation corpus manifest (5 carpaint + 5 synthetic) in `tools/validate-mtlx-pathtracer-corpus.mjs`

**Checkpoint**: New route and generator scaffold exist; deterministic naming and dependency guards are enforceable.

---

## Phase 3: User Story 1 - Isolated MTLX pathtracer route (Priority: P1)

**Goal**: Provide a separate viewer-side GLSL route that consumes a per-material generated dispatch artifact.

**Independent Test**: Confirm `glsl/pathtracing/mtlx/pathtracer.glsl` exists and the MTLX route includes exactly one generated dispatch artifact and no legacy `_brdf.glsl` or `_btdf.glsl` files.

### Implementation for User Story 1

- [ ] T015 [US1] Replace legacy OpenPBR dispatch calls in `glsl/pathtracing/mtlx/pathtracer.glsl` with an include point for the active per-material `generated_bsdf_dispatch.glsl`
- [ ] T016 [P] [US1] Remove direct dependency on `openpbr_bsdf_evaluate` from `glsl/pathtracing/mtlx/pathtracer.glsl`
- [ ] T017 [P] [US1] Remove direct dependency on `openpbr_bsdf_sample` from `glsl/pathtracing/mtlx/pathtracer.glsl`
- [ ] T018 [US1] Add MTLX route shader assembly branch that selects one generated dispatch artifact per active `.mtlx` in `main.js`
- [ ] T019 [US1] Add a route selection flag/mode for MTLX pathtracer in `main.js`
- [ ] T020 [US1] Add strict route assembly error when the expected generated dispatch artifact is missing in `main.js`
- [ ] T021 [US1] Run forbidden-dependency text check against `glsl/pathtracing/mtlx/**/*.glsl`

**Checkpoint**: MTLX pathtracer route is isolated from legacy BXDF implementations and selects one generated artifact.

---

## Phase 4: User Story 2 - C++ generated evaluate/sample dispatch (Priority: P2)

**Goal**: Emit per-material `evaluateBsdf` and `sampleBsdf` for all five supported models from the new MaterialX-rva generator.

**Independent Test**: Generate dispatch for the mixed corpus and verify each artifact contains generated `evaluateBsdf` and `sampleBsdf` definitions, is model-appropriate, and has no legacy BXDF references.

### Implementation for User Story 2

- [ ] T022 [US2] Implement MaterialX closure/model discovery for selected `.mtlx` documents in `MtlxPathTracerHostShaderGenerator.cpp`
- [ ] T023 [US2] Implement generated `evaluateBsdf` emission from the material closure graph in `MtlxPathTracerHostShaderGenerator.cpp`
- [ ] T024 [US2] Implement generated `sampleBsdf` emission from the material closure graph in `MtlxPathTracerHostShaderGenerator.cpp`
- [ ] T025 [US2] Implement generated helper/closure dependency emission (EDF/BSDF/BRDF/BTDF) in `MtlxPathTracerHostShaderGenerator.cpp`
- [ ] T026 [US2] Implement `open_pbr_surface` dispatch mapping in `MtlxPathTracerHostShaderGenerator.cpp`
- [ ] T027 [US2] Implement `standard_surface` dispatch mapping in `MtlxPathTracerHostShaderGenerator.cpp`
- [ ] T028 [US2] Implement `disney_principled` dispatch mapping in `MtlxPathTracerHostShaderGenerator.cpp`
- [ ] T029 [US2] Implement `gltf_pbr` dispatch mapping in `MtlxPathTracerHostShaderGenerator.cpp`
- [ ] T030 [US2] Implement `usd_preview_surface` dispatch mapping in `MtlxPathTracerHostShaderGenerator.cpp`
- [ ] T031 [US2] Add explicit failure for unsupported models and incomplete evaluate/sample/pdf strategies (no approximation) in `MtlxPathTracerHostShaderGenerator.cpp`
- [ ] T032 [US2] Wire generator wrapper to emit per-material artifacts for all corpus fixtures in `tools/generate-mtlx-pathtracer-dispatch.mjs`
- [ ] T033 [US2] Generate the five carpaint dispatch artifacts under `glsl/pathtracing/mtlx/generated/<material-id>/generated_bsdf_dispatch.glsl`
- [ ] T034 [US2] Author the five synthetic `.mtlx` fixtures under `artifacts/mtlx-pathtracer/fixtures/` and generate their dispatch artifacts under `glsl/pathtracing/mtlx/generated/<material-id>/generated_bsdf_dispatch.glsl`
- [ ] T035 [US2] Run text checks proving every generated artifact defines `evaluateBsdf`, `sampleBsdf`, and has no forbidden legacy references

**Checkpoint**: The generator produces valid per-material dispatch artifacts for all five models across the mixed corpus.

---

## Phase 5: User Story 3 - Viewer compile/render validation (Priority: P3)

**Goal**: Compile and validate the generated MTLX pathtracer route in the WebGL viewer for the full mixed corpus.

**Independent Test**: Build the viewer and run headless compile/render validation for every carpaint and synthetic fixture using the MTLX route.

### Implementation for User Story 3

- [ ] T036 [US3] Wire `launch_render.mjs` support for selecting the MTLX pathtracer route and active `.mtlx`
- [ ] T037 [US3] Run `npm run build` after MTLX route integration
- [ ] T038 [US3] Run headless compile/render for the five carpaint fixtures with the MTLX route enabled
- [ ] T039 [US3] Run headless compile/render for the five synthetic fixtures with the MTLX route enabled
- [ ] T040 [US3] Emit a validation report distinguishing carpaint vs synthetic outcomes in `artifacts/mtlx-pathtracer/validation/report.json`
- [ ] T041 [US3] Confirm no fallback to legacy pathtracer mode and no generic approximation path occurred during validation
- [ ] T042 [US3] Update `specs/003-mtlx-pathtracer-host-generator/quickstart.md` with final validated commands and outcomes

**Checkpoint**: All corpus fixtures compile/render through the generated MTLX route or fail explicitly with diagnostics.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, guardrails, and consistency checks across both repositories.

- [ ] T043 [P] Add README section documenting the MTLX pathtracer host generator workflow in `README.md`
- [ ] T044 [P] Add generator usage notes in `../MaterialX-rva/source/MaterialXGenGlsl/MtlxPathTracerHostShaderGenerator.h`
- [ ] T045 Add explicit note that `glsl/pathtracing/legacy/` remains manual reference only in `README.md`
- [ ] T046 [P] Add quick validation command for forbidden `PathTracerGlslShaderGenerator` implementation dependency in `specs/003-mtlx-pathtracer-host-generator/quickstart.md`
- [ ] T047 [P] Add quick validation command for forbidden legacy `_brdf`/`_btdf` dependencies in `specs/003-mtlx-pathtracer-host-generator/quickstart.md`
- [ ] T048 Run final consistency scan across `specs/003-mtlx-pathtracer-host-generator/`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Starts immediately.
- **Phase 2 (Foundational)**: Depends on Phase 1 and blocks all user stories.
- **Phase 3 (US1)**: Depends on Phase 2.
- **Phase 4 (US2)**: Depends on Phase 2 and can proceed alongside US1 with shared generated-artifact path coordination.
- **Phase 5 (US3)**: Depends on US1 route and US2 generated artifacts.
- **Phase 6 (Polish)**: Depends on selected user stories.

### User Story Dependencies

- **US1 (P1)**: Independent after foundational setup; creates viewer route isolation.
- **US2 (P2)**: Independent after foundational setup; creates per-material generated dispatch for all five models.
- **US3 (P3)**: Depends on US1 route and US2 generated artifacts.

### Within Each User Story

- C++ closure discovery before evaluate/sample emission.
- Evaluate/sample emission before per-model mapping.
- Per-model mapping before corpus artifact generation.
- Artifact generation before viewer compile/render validation.

### Parallel Opportunities

- Setup: T003, T004, T005 can run in parallel after T001/T002.
- Foundational: T008, T009, T013, T014 can run in parallel after T006/T007.
- US1: T016 and T017 can run in parallel after T015.
- US2: the five per-model mappings (T026-T030) can be parallelized after T022-T025.
- US3: carpaint and synthetic render batches (T038, T039) can run in parallel.
- Polish: T043, T044, T046, T047 can run in parallel.

---

## Parallel Example: User Story 2 per-model mappings

```bash
Task: "Implement open_pbr_surface dispatch mapping in MtlxPathTracerHostShaderGenerator.cpp"
Task: "Implement standard_surface dispatch mapping in MtlxPathTracerHostShaderGenerator.cpp"
Task: "Implement disney_principled dispatch mapping in MtlxPathTracerHostShaderGenerator.cpp"
Task: "Implement gltf_pbr dispatch mapping in MtlxPathTracerHostShaderGenerator.cpp"
Task: "Implement usd_preview_surface dispatch mapping in MtlxPathTracerHostShaderGenerator.cpp"
```

---

## Implementation Strategy

### MVP First

1. Complete Phase 1 and Phase 2.
2. Complete US1 route isolation with per-material artifact selection.
3. Complete US2 generator with all five model mappings and explicit failure policy.
4. Validate generated output with text checks before viewer integration.

### Incremental Delivery

1. Route scaffold, deterministic naming, and dependency guards.
2. C++ generator scaffold and closure discovery.
3. Per-material dispatch generation for the mixed corpus.
4. Viewer compile/render validation for carpaint and synthetic fixtures.
5. Cross-repo hardening and documentation.

---

## Notes

- This feature intentionally supersedes the direction of `002-wasm-bxdf-replacement` for the generator architecture.
- `PathTracerGlslShaderGenerator` must not be the implementation dependency for this chantier.
- Legacy `_brdf.glsl` and `_btdf.glsl` files remain comparison/reference assets only.
- All five material models are required in the first delivery; validation must cover both carpaint and synthetic fixtures.
