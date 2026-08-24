# Implementation Plan: MaterialX Pathtracer Host Generator

**Branch**: `003-mtlx-pathtracer-host-generator` | **Date**: 2026-08-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/003-mtlx-pathtracer-host-generator/spec.md`

## Summary

Create a new MaterialX pathtracer route under `glsl/pathtracing/mtlx/` and a new C++ host generator in `MaterialX-rva` that emits the pathtracer dispatch functions `evaluateBsdf` and `sampleBsdf` from selected `.mtlx` material graphs. The new generator is inspired by `EsslHostShaderGenerator`, does not use `PathTracerGlslShaderGenerator` as its implementation path, and must rely on MaterialX-generated EDF/BSDF/BRDF/BTDF functions instead of legacy `_brdf.glsl` or `_btdf.glsl` files.

## Technical Context

**Language/Version**: JavaScript ES modules, GLSL ES/WebGL2 shaders, C++ MaterialX generator code

**Primary Dependencies**: Three.js, Vite, playwright-core, sharp, MaterialXGenGlsl, MaterialX JavaScript/WASM build outputs

**Storage**: File-based GLSL templates, generated GLSL artifacts, MaterialX `.mtlx` files, validation reports

**Testing**: `npm run build`, headless render/compile via `launch_render.mjs`, generator output text checks, MaterialX-rva C++/WASM build validation where available

**Target Platform**: Browser WebGL viewer plus Windows MaterialX C++/WASM generator toolchain

**Project Type**: Cross-repo shader-generator integration for a WebGL pathtracer

**Performance Goals**: Preserve viewer compile/run workflow; generate and validate the first material (`open_pbr_carpaint.mtlx`) within an interactive development loop

**Constraints**: No production fallback to legacy BXDF files; no dependency on `PathTracerGlslShaderGenerator` for this chantier; generated dispatch must be material-model-aware and explicit on unsupported closures

**Scale/Scope**: Initial route and generator support for one selected material at a time, first proven on `D:\WebGL2\MaterialX\materials\open_pbr_carpaint.mtlx`, with design extensible to `standard_surface`, `disney_principled`, `gltf_pbr`, and `usd_preview_surface`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Status: PASS
- Generated shading authority is preserved because the new route consumes MaterialX-generated closures.
- Explicit runtime contracts are required through generator/viewer contracts in this feature.
- Deterministic failure is required for unsupported materials, missing closure functions, and incompatible signatures.
- Cross-repo discipline is required because viewer GLSL/JS changes and MaterialX-rva C++/WASM changes must be synchronized.
- Validation gates are required for absence of legacy `_brdf`/`_btdf` dependencies, build success, and first-material compile/render validation.

Post-Phase 1 Re-check:
- Design artifacts define a new generator contract, viewer assembly contract, generated dispatch entity, and quickstart validation commands.
- No constitutional violations are accepted for this feature.

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
│   └── mtlx-viewer-route-contract.md
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
    └── generated_bsdf_dispatch.glsl

tools/
└── generate-mtlx-pathtracer-dispatch.mjs

artifacts/
└── mtlx-pathtracer/
    ├── open_pbr_carpaint.generated.glsl
    └── open_pbr_carpaint.validation.json
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

**Structure Decision**: Keep the viewer route separate in `glsl/pathtracing/mtlx/` and create a distinct MaterialX-rva C++ generator class. `PathTracerGlslShaderGenerator` remains out of the implementation path for this chantier.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Cross-repo change | Required to generate dispatch from MaterialX C++ and consume it in the viewer | Viewer-only adapters would repeat the previous misaligned approach and keep dispatch hand-written |
