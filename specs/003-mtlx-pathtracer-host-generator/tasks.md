# Tasks: MaterialX Pathtracer Host Generator

**Input**: Design documents from `/specs/003-mtlx-pathtracer-host-generator/`

**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/, quickstart.md

**Tests**: Validation tasks are included as executable build, generation, text-check, and headless compile/render checks.

**Organization**: Tasks are grouped by user story for independent delivery and validation.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish the new route and generator scaffold without changing the legacy comparison path.

- [ ] T001 Create `glsl/pathtracing/mtlx/` directory
- [ ] T002 Copy `glsl/pathtracing/legacy/pathtracer.glsl` to `glsl/pathtracing/mtlx/pathtracer.glsl` as the initial base
- [ ] T003 [P] Create generated dispatch placeholder file `glsl/pathtracing/mtlx/generated_bsdf_dispatch.glsl`
- [ ] T004 [P] Create validation artifact directory `artifacts/mtlx-pathtracer/`
- [ ] T005 [P] Create generator wrapper scaffold `tools/generate-mtlx-pathtracer-dispatch.mjs`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Add cross-repo C++ generator scaffolding and explicit contracts before viewer integration.

**CRITICAL**: No user story implementation starts before this phase is complete.

- [ ] T006 Create C++ header `../MaterialX-rva/source/MaterialXGenGlsl/MtlxPathTracerHostShaderGenerator.h`
- [ ] T007 Create C++ implementation `../MaterialX-rva/source/MaterialXGenGlsl/MtlxPathTracerHostShaderGenerator.cpp`
- [ ] T008 [P] Document `EsslHostShaderGenerator`-inspired responsibilities inside `MtlxPathTracerHostShaderGenerator.h`
- [ ] T009 [P] Add explicit non-dependency guard against `PathTracerGlslShaderGenerator` in `MtlxPathTracerHostShaderGenerator.cpp`
- [ ] T010 Register the new generator in the appropriate MaterialXGenGlsl build/source registry files under `../MaterialX-rva/source/MaterialXGenGlsl/`
- [ ] T011 Update WASM generation exposure for the new generator in `../MaterialX-rva/javascript/`
- [ ] T012 Add text-check validation for forbidden legacy `_brdf`/`_btdf` dependencies in `tools/generate-mtlx-pathtracer-dispatch.mjs`

**Checkpoint**: New route and generator scaffold exist; legacy dependency guards are enforceable.

---

## Phase 3: User Story 1 - Isolated MTLX pathtracer route (Priority: P1)

**Goal**: Provide a separate viewer-side GLSL route for generated MaterialX pathtracer dispatch.

**Independent Test**: Confirm `glsl/pathtracing/mtlx/pathtracer.glsl` exists and the MTLX route does not include legacy `_brdf.glsl` or `_btdf.glsl` files.

### Implementation for User Story 1

- [ ] T013 [US1] Replace legacy OpenPBR dispatch calls in `glsl/pathtracing/mtlx/pathtracer.glsl` with inclusion/use of `generated_bsdf_dispatch.glsl`
- [ ] T014 [US1] Remove direct dependency on `openpbr_bsdf_evaluate` from `glsl/pathtracing/mtlx/pathtracer.glsl`
- [ ] T015 [US1] Remove direct dependency on `openpbr_bsdf_sample` from `glsl/pathtracing/mtlx/pathtracer.glsl`
- [ ] T016 [US1] Add MTLX route shader assembly branch in `main.js`
- [ ] T017 [US1] Add a route selection flag or mode for MTLX pathtracer in `main.js`
- [ ] T018 [US1] Add strict route assembly error when `generated_bsdf_dispatch.glsl` is missing in `main.js`
- [ ] T019 [US1] Run forbidden dependency text check against `glsl/pathtracing/mtlx/*.glsl`

**Checkpoint**: MTLX pathtracer route is independently inspectable and isolated from legacy BXDF implementations.

---

## Phase 4: User Story 2 - C++ generated evaluate/sample dispatch (Priority: P2)

**Goal**: Emit pathtracer-compatible `evaluateBsdf` and `sampleBsdf` from the new MaterialX-rva generator.

**Independent Test**: Generate GLSL for `D:\WebGL2\MaterialX\materials\open_pbr_carpaint.mtlx` and verify the output contains generated `evaluateBsdf` and `sampleBsdf` definitions with no legacy BXDF references.

### Implementation for User Story 2

- [ ] T020 [US2] Implement generated `evaluateBsdf` emission in `../MaterialX-rva/source/MaterialXGenGlsl/MtlxPathTracerHostShaderGenerator.cpp`
- [ ] T021 [US2] Implement generated `sampleBsdf` emission in `../MaterialX-rva/source/MaterialXGenGlsl/MtlxPathTracerHostShaderGenerator.cpp`
- [ ] T022 [US2] Implement MaterialX closure/model discovery for selected `.mtlx` documents in `MtlxPathTracerHostShaderGenerator.cpp`
- [ ] T023 [US2] Implement generated helper/closure dependency emission in `MtlxPathTracerHostShaderGenerator.cpp`
- [ ] T024 [US2] Add explicit unsupported material model diagnostics in `MtlxPathTracerHostShaderGenerator.cpp`
- [ ] T025 [US2] Add generator wrapper execution for `open_pbr_carpaint.mtlx` in `tools/generate-mtlx-pathtracer-dispatch.mjs`
- [ ] T026 [US2] Emit `glsl/pathtracing/mtlx/generated_bsdf_dispatch.glsl` for `open_pbr_carpaint.mtlx`
- [ ] T027 [US2] Generate validation report `artifacts/mtlx-pathtracer/open_pbr_carpaint.validation.json`
- [ ] T028 [US2] Run text checks proving generated output has `evaluateBsdf`, `sampleBsdf`, and no forbidden legacy references

**Checkpoint**: New C++ generator produces the requested dispatch GLSL for the first material.

---

## Phase 5: User Story 3 - Viewer compile/render validation (Priority: P3)

**Goal**: Compile and validate the generated MTLX pathtracer route in the WebGL viewer.

**Independent Test**: Build the viewer and run headless compile/render validation for `open_pbr_carpaint.mtlx` using the MTLX route.

### Implementation for User Story 3

- [ ] T029 [US3] Wire `launch_render.mjs` support for selecting the MTLX pathtracer route
- [ ] T030 [US3] Run `npm run build` after MTLX route integration
- [ ] T031 [US3] Run headless render for `D:\WebGL2\MaterialX\materials\open_pbr_carpaint.mtlx` with MTLX route enabled
- [ ] T032 [US3] Record shader compile/render outcome in `artifacts/mtlx-pathtracer/open_pbr_carpaint.validation.json`
- [ ] T033 [US3] Confirm no fallback to legacy pathtracer mode occurred during validation
- [ ] T034 [US3] Update `specs/003-mtlx-pathtracer-host-generator/quickstart.md` with final validated commands and outcomes

**Checkpoint**: First material compiles/renders through the generated MTLX route.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, guardrails, and consistency checks across both repositories.

- [ ] T035 [P] Add README section documenting the MTLX pathtracer host generator workflow in `README.md`
- [ ] T036 [P] Add generator usage notes in `../MaterialX-rva/source/MaterialXGenGlsl/MtlxPathTracerHostShaderGenerator.h`
- [ ] T037 Add explicit comparison note that `glsl/pathtracing/legacy/` remains manual reference only in `README.md`
- [ ] T038 Add quick validation command for forbidden `PathTracerGlslShaderGenerator` implementation dependency in `specs/003-mtlx-pathtracer-host-generator/quickstart.md`
- [ ] T039 Add quick validation command for forbidden legacy `_brdf`/`_btdf` dependencies in `specs/003-mtlx-pathtracer-host-generator/quickstart.md`
- [ ] T040 Run final consistency scan across `specs/003-mtlx-pathtracer-host-generator/`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Starts immediately.
- **Phase 2 (Foundational)**: Depends on Phase 1 and blocks all user stories.
- **Phase 3 (US1)**: Depends on Phase 2.
- **Phase 4 (US2)**: Depends on Phase 2 and can proceed alongside US1 with shared generated-file coordination.
- **Phase 5 (US3)**: Depends on US1 and US2.
- **Phase 6 (Polish)**: Depends on selected user stories.

### User Story Dependencies

- **US1 (P1)**: Independent after foundational setup; creates viewer route isolation.
- **US2 (P2)**: Independent after foundational setup; creates generated dispatch.
- **US3 (P3)**: Depends on US1 route and US2 generated dispatch.

### Parallel Opportunities

- Setup: T003, T004, T005 can run in parallel after T001/T002.
- Foundational: T008 and T009 can run in parallel after T006/T007.
- US1: T014 and T015 can run in parallel after T013.
- US2: T020 and T021 can be implemented together with careful same-file coordination; T025 can be prepared independently.
- Polish: T035, T036, T038, T039 can run in parallel.

---

## Implementation Strategy

### MVP First

1. Complete Phase 1 and Phase 2.
2. Complete US1 route isolation.
3. Complete enough of US2 to generate `evaluateBsdf` and `sampleBsdf` for `open_pbr_carpaint.mtlx`.
4. Validate generated output with text checks before viewer integration.

### Incremental Delivery

1. Route scaffold and contracts.
2. C++ generator scaffold.
3. First material dispatch generation.
4. Viewer compile/render integration.
5. Broaden material model coverage after first validation passes.

---

## Notes

- This feature intentionally supersedes the direction of `002-wasm-bxdf-replacement` for the generator architecture.
- `PathTracerGlslShaderGenerator` must not be the implementation dependency for this chantier.
- Legacy `_brdf.glsl` and `_btdf.glsl` files remain comparison/reference assets only.
