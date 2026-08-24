# Requirements Checklist - MaterialX Pathtracer Host Generator

**Purpose**: Validate that the feature specification is complete and internally coherent before implementation.
**Created**: 2026-08-24
**Feature**: [spec.md](../spec.md)

## Content Quality

- [x] No implementation placeholders remain in spec.md
- [x] User stories are prioritized and independently testable
- [x] Requirements are measurable and unambiguous
- [x] Success criteria are tied to executable or inspectable evidence
- [x] Edge cases cover unsupported material models and missing generated dispatch

## Scope Alignment

- [x] Spec requires `glsl/pathtracing/mtlx/`
- [x] Spec requires a copy of `glsl/pathtracing/legacy/pathtracer.glsl` as the initial route base
- [x] Spec requires generated `evaluateBsdf` and `sampleBsdf`
- [x] Spec requires a new C++ generator in `MaterialX-rva`
- [x] Spec names `EsslHostShaderGenerator` as the primary inspiration
- [x] Spec explicitly excludes `PathTracerGlslShaderGenerator` from the implementation path
- [x] Spec forbids dependency on legacy `_brdf.glsl` and `_btdf.glsl`
- [x] Spec requires first validation on `D:\WebGL2\MaterialX\materials\open_pbr_carpaint.mtlx`

## Readiness

- [x] Plan maps source and external repository paths concretely
- [x] Contracts define generator and viewer route responsibilities
- [x] Tasks use exact paths and avoid wildcards for cross-repo changes
- [x] Validation commands are documented in quickstart.md
