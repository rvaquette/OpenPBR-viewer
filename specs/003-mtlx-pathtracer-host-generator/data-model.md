# Data Model - MaterialX Pathtracer Host Generator

## Entity: MtlxPathtracerRoute
- Description: Viewer-side pathtracer route dedicated to MaterialX-generated host dispatch.
- Fields:
  - routeId (string, required)
  - pathtracerFile (path, required; expected `glsl/pathtracing/mtlx/pathtracer.glsl`)
  - generatedDispatchFile (path, required)
  - legacyDependencyStatus (enum: none, violation, unknown)
- Validation rules:
  - route must not include `glsl/pathtracing/legacy/*_brdf.glsl` or `glsl/pathtracing/legacy/*_btdf.glsl`.
  - route must assemble separately from legacy comparison mode.

## Entity: MtlxPathTracerHostGenerator
- Description: New MaterialX-rva C++ generator responsible for pathtracer host dispatch GLSL.
- Fields:
  - className (string, required; expected `MtlxPathTracerHostShaderGenerator`)
  - headerPath (path, required)
  - implementationPath (path, required)
  - inspirationSource (string, required; expected `EsslHostShaderGenerator`)
  - forbiddenDependency (string, required; expected `PathTracerGlslShaderGenerator`)
- Validation rules:
  - implementation path must not instantiate or inherit from `PathTracerGlslShaderGenerator`.
  - any copied/adapted helper concept must be documented inside the new generator source.

## Entity: GeneratedBsdfDispatch
- Description: GLSL emitted by the new generator for one selected `.mtlx` material graph.
- Fields:
  - materialId (string, required)
  - sourceMtlxPath (path, required)
  - generatedAt (datetime, required)
  - evaluateFunctionName (string, required; expected `evaluateBsdf`)
  - sampleFunctionName (string, required; expected `sampleBsdf`)
  - helperFunctionsUsed (array<string>, required)
  - legacyReferences (array<string>, required)
- Validation rules:
  - must contain definitions for `evaluateBsdf` and `sampleBsdf`.
  - `legacyReferences` must be empty.

## Entity: MaterialModelAdapter
- Description: Maps the selected MaterialX material model to pathtracer dispatch requirements.
- Fields:
  - materialModel (enum: open_pbr_surface, standard_surface, disney_principled, gltf_pbr, usd_preview_surface, other)
  - closureKinds (array<enum: EDF, BSDF, BRDF, BTDF>, required)
  - samplingPolicy (string, required)
  - pdfPolicy (string, required)
- Validation rules:
  - unsupported closure kinds fail before viewer shader compile.
  - sampling and PDF policies must be explicit for each supported model.

## Entity: GenerationValidationArtifact
- Description: Evidence produced by generation and viewer validation.
- Fields:
  - sourceMtlxPath (path, required)
  - generatedGlslPath (path, required)
  - buildStatus (enum: success, failure, required)
  - viewerCompileStatus (enum: success, failure, skipped, required)
  - legacyDependencyCheckStatus (enum: success, failure, required)
  - failureCause (string, optional)
- Validation rules:
  - `failureCause` is required when any status is failure.
  - release validation requires buildStatus, viewerCompileStatus, and legacyDependencyCheckStatus to be success.

## State Transitions
- MtlxPathtracerRoute: missing -> seeded -> integrated -> validated
- MtlxPathTracerHostGenerator: absent -> scaffolded -> emitting-dispatch -> wasm-ready -> validated
- GeneratedBsdfDispatch: absent -> generated -> checked -> viewer-compiled
- GenerationValidationArtifact: draft -> pass | fail
