# Implementation Plan: MaterialX Pathtracer Host Generator

**Branch**: `003-mtlx-pathtracer-host-generator` | **Date**: 2026-08-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/003-mtlx-pathtracer-host-generator/spec.md`

## Summary

Create a dedicated MaterialX pathtracer route under `glsl/pathtracing/mtlx/` and a new C++ host generator in `MaterialX-rva` that emits per-material `generated_bsdf_dispatch.glsl` artifacts. Each generated artifact supplies `evaluateBsdf` and `sampleBsdf` for one selected `.mtlx` material and is included by the copied MTLX pathtracer route. The first delivery must support `open_pbr_surface`, `standard_surface`, `disney_principled`, `gltf_pbr`, and `usd_preview_surface`, validated with both existing carpaint fixtures and simple synthetic fixtures. The generator is inspired by `EsslHostShaderGenerator`, must not use `PathTracerGlslShaderGenerator` as its implementation path, and must fail explicitly for unsupported closures or incomplete evaluate/sample/pdf strategies.

## Technical Context

**Language/Version**: JavaScript ES modules, GLSL ES/WebGL2 shaders, C++ MaterialX generator code

**Primary Dependencies**: Three.js, Vite, playwright-core, sharp, MaterialXGenGlsl, MaterialX JavaScript/WASM generation outputs

**Storage**: File-based GLSL templates, generated GLSL dispatch artifacts, MaterialX `.mtlx` fixtures, JSON validation reports

**Testing**: `npm run build`, text checks for forbidden dependencies, generator output validation, headless shader compile/render via `launch_render.mjs`, MaterialX-rva C++/WASM build checks where available

**Target Platform**: Browser WebGL viewer plus Windows MaterialX C++/WASM generator toolchain

**Project Type**: Cross-repo shader-generator integration for a WebGL pathtracer

**Performance Goals**: Keep generator/viewer validation in an interactive development loop; no runtime fallback paths that hide unsupported material behavior

**Constraints**: No production fallback to legacy BXDF files; no generic BRDF approximation for unsupported closures; no dependency on `PathTracerGlslShaderGenerator`; deterministic per-material dispatch artifact naming

**Scale/Scope**: First delivery covers five MaterialX material models: `open_pbr_surface`, `standard_surface`, `disney_principled`, `gltf_pbr`, `usd_preview_surface`; validation covers five existing carpaint files plus one simple synthetic fixture per model

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Status: PASS
- Generated shading authority is preserved because generated MaterialX closures are the only allowed material shading source for the MTLX route.
- Explicit runtime contracts are required through generator, viewer route, and validation corpus contracts.
- Deterministic failure is required for unsupported models, missing closures, signature mismatches, and incomplete evaluate/sample/pdf policies.
- Cross-repo discipline is required because viewer GLSL/JS changes and MaterialX-rva C++/WASM changes must be synchronized.
- Validation and release gates are required for all carpaint and synthetic fixtures, plus absence of legacy `_brdf`/`_btdf` dependencies.

Post-Phase 1 Re-check:
- Research/design artifacts define the new generator boundary, per-material artifact strategy, mixed validation corpus, and explicit failure policy.
- No constitutional violations remain open.

## Project Structure

### Documentation (this feature)

```text
specs/003-mtlx-pathtracer-host-generator/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── mtlx-pathtracer-generator-contract.md
│   ├── mtlx-viewer-route-contract.md
│   └── validation-corpus-contract.md
└── tasks.md
```

### Source Code (repository root)

```text
main.js
launch_render.mjs

glsl/pathtracing/
├── main.glsl
├── mtlx_host.glsl
├── mtlx_adapters.glsl
├── pathtracer.glsl
├── legacy/
└── mtlx/
  ├── pathtracer.glsl
  └── generated/
    ├── open_pbr_carpaint/generated_bsdf_dispatch.glsl
    ├── standard_surface_carpaint/generated_bsdf_dispatch.glsl
    ├── disney_principled_carpaint/generated_bsdf_dispatch.glsl
    ├── gltf_pbr_carpaint/generated_bsdf_dispatch.glsl
    ├── usd_preview_surface_carpaint/generated_bsdf_dispatch.glsl
    └── synthetic_<model>/generated_bsdf_dispatch.glsl

tools/
└── generate-mtlx-pathtracer-dispatch.mjs

artifacts/mtlx-pathtracer/
├── fixtures/            # synthetic .mtlx source fixtures only
├── generated/
└── validation/
```

### External Generator Repository

```text
../MaterialX-rva/source/MaterialXGenGlsl/
├── EsslHostShaderGenerator.cpp
├── EsslHostShaderGenerator.h
├── MtlxPathTracerHostShaderGenerator.cpp
└── MtlxPathTracerHostShaderGenerator.h

../MaterialX-rva/javascript/
├── build_javascript_win.bat
└── package.json
```

**Structure Decision**: Keep the viewer route separate in `glsl/pathtracing/mtlx/`, generate per-material dispatch artifacts under deterministic subdirectories, and create a distinct MaterialX-rva C++ generator class. `PathTracerGlslShaderGenerator` remains outside the implementation path for this chantier.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Cross-repo change | Required to generate dispatch from MaterialX C++ and consume it in the viewer | Viewer-only adapters would repeat the previous misaligned approach and keep dispatch hand-written |
| Multi-model first delivery | User selected full listed model coverage for MVP | OpenPBR-only MVP would leave the central material-model abstraction unproven |
