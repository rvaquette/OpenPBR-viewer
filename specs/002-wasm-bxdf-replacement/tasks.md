# Tasks: WASM BXDF Replacement

**Input**: Design documents from `/specs/002-wasm-bxdf-replacement/`

**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/, quickstart.md

**Tests**: The specification does not request a full test framework migration. Validation tasks are included as executable rendering and conformance checks.

**Organization**: Tasks are grouped by user story for independent delivery and validation.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare validation tooling and cross-repo ABI check utilities.

- [ ] T001 Add substitution workflow scripts in package.json
- [ ] T002 Create substitution runner scaffold in tools/run-substitution-validation.mjs
- [ ] T003 [P] Create substitution report schema validator in tools/validate-substitution-report.mjs
- [ ] T004 [P] Create generator ABI conformance checker script in tools/check-generator-abi.mjs

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish strict-failure runtime contract and ABI gate shared by all user stories.

**CRITICAL**: No user story implementation starts before this phase is complete.

- [ ] T005 Implement per-material contract loader and runtime binding in main.js
- [ ] T006 [P] Implement generated-function registry and signature lookup in public/mtlx/generated-function-registry.mjs
- [ ] T007 Enforce strict no-fallback failure path in glsl/pathtracing/main.glsl
- [ ] T008 [P] Wire strict-failure diagnostics bridge to runtime state in main.js
- [ ] T009 Implement substitution report writer core in tools/substitution-report.mjs
- [ ] T010 Wire report schema validation into substitution runner in tools/run-substitution-validation.mjs
- [ ] T011 Add ABI manifest conformance check integration in tools/run-substitution-validation.mjs

**Checkpoint**: Foundational contract, strict failure behavior, and report/ABI gates are ready.

---

## Phase 3: User Story 1 - Substitution des BXDF Legacy (Priority: P1)

**Goal**: Execute generated shading in main pathtracer flow and remove legacy BXDF main-flow usage.

**Independent Test**: Run pathtracer on representative materials and confirm generated functions are used while legacy main-flow BXDF path is not used.

### Implementation for User Story 1

- [ ] T012 [P] [US1] Refactor generated entrypoint mapping per material contract in glsl/pathtracing/mtlx_adapters.glsl
- [ ] T013 [US1] Replace legacy BXDF main-flow call sites with generated entrypoints in glsl/pathtracing/pathtracer.glsl
- [ ] T014 [US1] Update shader assembly routing to prioritize generated shading in main.js
- [ ] T015 [US1] Keep manual legacy comparison disabled by default in production path in main.js
- [ ] T016 [US1] Add strict-failure substitution flags in launch_render.mjs
- [ ] T017 [US1] Document substitution runtime behavior in README.md

**Checkpoint**: US1 is independently functional and demonstrable.

---

## Phase 4: User Story 2 - Contrat d’Intégration Stable (Priority: P2)

**Goal**: Ensure regenerated outputs remain ABI-compatible and diagnosable, including C++ PathTracerShaderGenerator conformance.

**Independent Test**: Regenerate from updated C++ generator and verify ABI conformance plus explicit failure diagnostics for mismatches.

### Implementation for User Story 2

- [ ] T018 [P] [US2] Add generator version binding and propagation in main.js
- [ ] T019 [P] [US2] Implement signature compatibility checks for required symbols in public/mtlx/generated-function-registry.mjs
- [ ] T020 [US2] Add contract validation stage before shader compile in main.js
- [ ] T021 [US2] Implement normalized contract failure causes in tools/substitution-report.mjs
- [ ] T022 [US2] Update C++ generator entrypoint/signature conformance in ../MaterialX-rva/source/MaterialXGenGlsl/PathTracerGlslShaderGenerator.cpp
- [ ] T023 [US2] Update matching C++ generator declarations in ../MaterialX-rva/source/MaterialXGenGlsl/PathTracerGlslShaderGenerator.h
- [ ] T024 [US2] Update WASM generation flow after C++ changes in ../MaterialX-rva/javascript/build_javascript_win.bat and ../MaterialX-rva/javascript/package.json
- [ ] T025 [US2] Publish regenerated artifacts for viewer runtime consumption in public/mtlx/
- [ ] T026 [US2] Add explicit ABI contract checks against generated output in tools/check-generator-abi.mjs
- [ ] T027 [US2] Update runtime integration contract details in specs/002-wasm-bxdf-replacement/contracts/generated-shading-contract.md

**Checkpoint**: US2 is independently functional with C++ generator conformance and ABI checks.

---

## Phase 5: User Story 3 - Validation de Non-Régression Visuelle (Priority: P3)

**Goal**: Produce structured substitution reports with release-gating logic and manual comparison workflow.

**Independent Test**: Run corpus validation and confirm each material emits required report fields and critical-difference gate decisions.

### Implementation for User Story 3

- [ ] T028 [P] [US3] Implement corpus batch execution and per-material timing capture in tools/run-substitution-validation.mjs
- [ ] T029 [P] [US3] Emit all required report fields including WASM generation version in tools/substitution-report.mjs
- [ ] T030 [US3] Add explicit manual-vs-automated boundary contract in specs/002-wasm-bxdf-replacement/contracts/manual-comparison-boundary.md
- [ ] T031 [US3] Implement ingestion of manually produced comparison categories (energy/hue/detail/mixed) in tools/run-substitution-validation.mjs
- [ ] T032 [US3] Implement critical-difference release gate decision from manual comparison inputs in tools/run-substitution-validation.mjs
- [ ] T033 [US3] Add manual comparison workflow conventions in legacy-mtlx/README.md
- [ ] T034 [US3] Update validation runbook with C++ regeneration + report flow in specs/002-wasm-bxdf-replacement/quickstart.md

**Checkpoint**: US3 is independently functional with release gating.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final cleanup, cross-repo traceability, and rollout hardening.

- [ ] T035 [P] Mark legacy comparison-only intent in glsl/pathtracing/legacy/openpbr_surface.glsl
- [ ] T036 [P] Mark legacy comparison-only intent in glsl/pathtracing/legacy/pathtracer.glsl
- [ ] T037 Add substitution report sample artifact in specs/002-wasm-bxdf-replacement/contracts/substitution-report.sample.json
- [ ] T038 [P] Add strict-failure and ABI troubleshooting guide in README.md
- [ ] T039 Add explicit SC-003 and SC-005 KPI assertions (95% pass rate, 15-minute integration target) in tools/run-substitution-validation.mjs
- [ ] T040 Add runtime stability watchdog validation (no crash/no unbounded loop) in tools/run-substitution-validation.mjs
- [ ] T041 Add ABI conformance quick check commands in specs/002-wasm-bxdf-replacement/quickstart.md
- [ ] T042 Run end-to-end quickstart validation and record outcomes in specs/002-wasm-bxdf-replacement/quickstart.md

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Starts immediately.
- **Phase 2 (Foundational)**: Depends on Phase 1 and blocks all user stories.
- **Phase 3 (US1)**: Depends on Phase 2.
- **Phase 4 (US2)**: Depends on Phase 2; may run in parallel with US1 with shared-file coordination.
- **Phase 5 (US3)**: Depends on Phase 2 and benefits from report core and ABI checks.
- **Phase 6 (Polish)**: Depends on completion of selected user stories.

### User Story Dependencies

- **US1 (P1)**: Independent after foundational.
- **US2 (P2)**: Independent after foundational; includes external C++ generator and WASM regeneration steps.
- **US3 (P3)**: Independent after foundational; consumes shared reporting/validation utilities.

### Within Each User Story

- Runtime and mapping before CLI/docs updates.
- C++ generator updates before WASM regeneration and artifact publication.
- Manual comparison evidence capture before automated gate evaluation.
- Report field emission before KPI assertions and release gate evaluation.

### Parallel Opportunities

- Setup: T003, T004 in parallel after T001/T002 initialization.
- Foundational: T006 and T008 can run in parallel after T005 starts.
- US1: T012 can run before T013/T014 integration.
- US2: T018 and T019 in parallel; T022 and T023 can be coordinated in parallel by generator/toolchain owners.
- US3: T028 and T029 in parallel before T031/T032.
- Polish: T035, T036, T038 in parallel.

---

## Parallel Example: User Story 2

```bash
# Parallelizable contract stabilization
Task: "Implement generator version binding and propagation in main.js"
Task: "Implement signature compatibility checks for required symbols in public/mtlx/generated-function-registry.mjs"

# Cross-repo generator updates
Task: "Update C++ PathTracerGlslShaderGenerator entrypoint/signature conformance in ../MaterialX-rva/source/MaterialXGenGlsl/PathTracerGlslShaderGenerator.cpp"
Task: "Update WASM generation flow after C++ changes in ../MaterialX-rva/javascript/build_javascript_win.bat and ../MaterialX-rva/javascript/package.json"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 and Phase 2.
2. Complete US1 tasks in Phase 3.
3. Validate strict no-fallback behavior on representative materials.

### Incremental Delivery

1. Foundation first (Phases 1-2).
2. Deliver US1 runtime substitution.
3. Deliver US2 C++/WASM ABI conformance and regeneration path.
4. Deliver US3 reporting and release gating.
5. Execute Phase 6 hardening and runbook completion.

### Parallel Team Strategy

1. Team A: Viewer runtime and GLSL integration (main.js, glsl/pathtracing/*).
2. Team B: Validation/report tooling (tools/*.mjs).
3. Team C: Generator/toolchain updates (../MaterialX-rva/source/MaterialXGenGlsl, ../MaterialX-rva/javascript).
4. Team D: Documentation and rollout runbooks (README.md, specs/002-wasm-bxdf-replacement/*).

---

## Notes

- All tasks follow required checklist format with IDs and file paths.
- [P] marks tasks that can run in parallel without unresolved dependencies.
- User story labels appear only in user story phases.
- Legacy comparison stays outside automated production pipeline.
