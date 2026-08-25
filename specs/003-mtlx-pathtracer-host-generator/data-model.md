# Data Model - MaterialX Pathtracer Host Generator

## Entity: MtlxPathtracerRoute
- Description: Viewer-side pathtracer route dedicated to MaterialX-generated host dispatch.
- Fields:
  - routeId (string, required)
  - pathtracerFile (path, required; `glsl/pathtracing/mtlx/pathtracer.glsl`)
  - generatedDispatchRoot (path, required; deterministic per-material dispatch directories)
  - activeDispatchPath (path, required at runtime)
  - legacyDependencyStatus (enum: none, violation, unknown)
- Validation rules:
  - route must not include `glsl/pathtracing/legacy/*_brdf.glsl` or `glsl/pathtracing/legacy/*_btdf.glsl`.
  - route must select exactly one generated dispatch artifact for the active `.mtlx` material.

## Entity: MtlxPathTracerHostShaderGenerator
- Description: New MaterialX-rva C++ generator responsible for pathtracer host dispatch GLSL.
- Fields:
  - className (string, required; `MtlxPathTracerHostShaderGenerator`)
  - headerPath (path, required)
  - implementationPath (path, required)
  - inspirationSource (string, required; `EsslHostShaderGenerator`)
  - forbiddenImplementationDependency (string, required; `PathTracerGlslShaderGenerator`)
  - supportedModels (array<string>, required)
- Validation rules:
  - implementation must not instantiate, inherit from, or require `PathTracerGlslShaderGenerator`.
  - supportedModels must include `open_pbr_surface`, `standard_surface`, `disney_principled`, `gltf_pbr`, and `usd_preview_surface`.

## Entity: GeneratedBsdfDispatch
- Description: Per-material GLSL emitted by the new generator.
- Fields:
  - materialId (string, required)
  - materialModel (string, required)
  - sourceMtlxPath (path, required)
  - generatedDispatchPath (path, required)
  - evaluateFunctionName (string, required; `evaluateBsdf`)
  - sampleFunctionName (string, required; `sampleBsdf`)
  - closureFunctionsUsed (array<string>, required)
  - helperFunctionsUsed (array<string>, required)
  - legacyReferences (array<string>, required)
- Validation rules:
  - must contain definitions for `evaluateBsdf` and `sampleBsdf`.
  - `legacyReferences` must be empty.
  - generatedDispatchPath must be deterministic from materialId/source path.

## Entity: MaterialModelAdapter
- Description: Model-specific mapping from MaterialX generated closure output to the pathtracer dispatch contract.
- Fields:
  - materialModel (enum: open_pbr_surface, standard_surface, disney_principled, gltf_pbr, usd_preview_surface)
  - closureKinds (array<enum: EDF, BSDF, BRDF, BTDF>, required)
  - evaluatePolicy (string, required)
  - samplingPolicy (string, required)
  - pdfPolicy (string, required)
- Validation rules:
  - unsupported closure kinds fail before GLSL artifact publication.
  - evaluatePolicy, samplingPolicy, and pdfPolicy must all be present.

## Entity: ValidationFixture
- Description: One material fixture in the mixed validation corpus.
- Fields:
  - fixtureId (string, required)
  - fixtureType (enum: carpaint, synthetic, required)
  - materialModel (string, required)
  - sourceMtlxPath (path, required)
  - generatedDispatchPath (path, required)
- Validation rules:
  - each required material model must have one carpaint fixture and one synthetic fixture.

## Entity: GenerationValidationArtifact
- Description: Evidence produced by generation and viewer validation.
- Fields:
  - fixtureId (string, required)
  - fixtureType (enum: carpaint, synthetic, required)
  - sourceMtlxPath (path, required)
  - generatedGlslPath (path, required)
  - generationStatus (enum: success, failure, required)
  - legacyDependencyCheckStatus (enum: success, failure, required)
  - viewerCompileStatus (enum: success, failure, skipped, required)
  - failureCause (string, optional)
- Validation rules:
  - `failureCause` is required when any status is failure.
  - release validation requires all statuses to be success for all fixtures.

## State Transitions
- MtlxPathtracerRoute: missing -> seeded -> integrated -> validated
- MtlxPathTracerHostShaderGenerator: absent -> scaffolded -> emitting-dispatch -> wasm-ready -> validated
- GeneratedBsdfDispatch: absent -> generated -> checked -> viewer-compiled
- ValidationFixture: declared -> generated -> validated
- GenerationValidationArtifact: draft -> pass | fail
