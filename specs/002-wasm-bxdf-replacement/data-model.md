# Data Model - WASM BXDF Replacement

## Entity: MaterialContract
- Description: Declares required generated shading functions for one material.
- Fields:
  - materialId (string, required)
  - wasmGenerationVersion (string, required)
  - requiredFunctions (array<string>, required)
  - optionalFunctions (array<string>, optional)
  - contractStatus (enum: valid, invalid, unknown)
- Validation rules:
  - requiredFunctions must be non-empty for contracts marked valid.
  - function names must match exported generated-symbol naming rules.

## Entity: GeneratedFunctionSet
- Description: Captures generated BSDF/EDF/BRDF and helper functions for one material build.
- Fields:
  - materialId (string, required)
  - functions (array<GeneratedFunction>, required)
  - sourceHash (string, required)
  - generatedAt (datetime, required)
- Validation rules:
  - function signatures must parse and resolve against IntegrationContract expectations.

## Entity: IntegrationContract
- Description: Runtime integration requirements between generated output and pathtracer entry points.
- Fields:
  - contractId (string, required)
  - requiredEntryPoints (array<string>, required)
  - signatureRules (array<string>, required)
  - strictFailureEnabled (boolean, required; expected true)
  - comparisonMode (enum: manual-only, required)
- Validation rules:
  - strictFailureEnabled must be true for this feature scope.
  - comparisonMode must be manual-only.

## Entity: GeneratorAbiManifest
- Description: Declares the GLSL ABI produced by the C++ PathTracerGlslShaderGenerator for one generator version.
- Fields:
  - generatorVersion (string, required)
  - exportedEntryPoints (array<string>, required)
  - signatureMap (map<string,string>, required)
  - helperFunctionSet (array<string>, optional)
  - conformsToLegacyExpectations (boolean, required)
- Validation rules:
  - exportedEntryPoints and signatureMap keys must be consistent.
  - conformsToLegacyExpectations is true only when all mandatory legacy expected entries are present.

## Entity: LegacyExpectationMap
- Description: Canonical mapping of legacy pathtracing expected function names/signatures.
- Fields:
  - expectationVersion (string, required)
  - requiredSymbols (array<string>, required)
  - requiredSignatures (map<string,string>, required)
  - optionalSymbols (array<string>, optional)
- Validation rules:
  - Every required symbol must have a required signature.

## Entity: SubstitutionRun
- Description: One execution of substitution validation over a corpus.
- Fields:
  - runId (string, required)
  - wasmGenerationVersion (string, required)
  - startedAt (datetime, required)
  - completedAt (datetime, optional)
  - entries (array<SubstitutionReportEntry>, required)

## Entity: SubstitutionReportEntry
- Description: Per-material substitution and validation outcome.
- Fields:
  - materialId (string, required)
  - substitutionStatus (enum: success, failure, required)
  - renderStatus (enum: success, failure, required)
  - generatedFunctionsUsed (array<string>, required)
  - failureCause (string, optional)
  - visualDifferenceType (enum: none, energy, hue, detail, mixed, required)
  - renderTimeMs (number, required)
  - wasmGenerationVersion (string, required)
  - criticalDifference (boolean, required)
- Validation rules:
  - failureCause required when substitutionStatus or renderStatus is failure.
  - criticalDifference true when visualDifferenceType implies major energy/hue/detail divergence.

## State Transitions
- MaterialContract: unknown -> valid | invalid
- GeneratorAbiManifest: draft -> conformant | non-conformant
- SubstitutionReportEntry:
  - pending -> success
  - pending -> failure
  - success -> flagged-critical (if manual comparison marks critical)
