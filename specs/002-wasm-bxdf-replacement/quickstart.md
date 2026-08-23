# Quickstart - WASM BXDF Replacement

## 1. Install and run viewer
1. Install dependencies:
   - `npm install`
2. Start dev server:
   - `npx vite`
3. Open:
   - `http://localhost:5173/OpenPBR-viewer`

## 2. Build generated-shading context
1. Ensure MaterialX WASM generator artifacts are available to the viewer runtime.
2. Load a target material and verify generated shading payload is present before pathtracer compile.

## 2b. Apply C++ generator conformance updates
1. In the MaterialX generator repository, update PathTracerShaderGenerator implementation to match legacy GLSL expectations.
2. Regenerate WASM shading artifacts from the updated C++ generator.
3. Publish regenerated artifacts to the viewer runtime location used by this repository.
4. Verify exported entrypoints and signatures against contracts/generator-abi-contract.md.

## 3. Execute substitution validation run
1. Run a pathtracer capture with target material:
   - `node launch_render.mjs --mtlx=<path-to-material.mtlx> --mode="Pathtracer" --spp=24`
2. Confirm the run uses generated functions and does not invoke legacy main-flow BXDF modules.

## 4. Validate strict failure behavior
1. Use a material with intentionally broken/missing generated function mapping.
2. Verify behavior:
   - Material fails explicitly.
   - No automatic fallback to legacy BXDF path.

## 5. Produce report entries
For each material in corpus, collect:
- substitutionStatus
- renderStatus
- generatedFunctionsUsed
- failureCause (if applicable)
- visualDifferenceType
- renderTimeMs
- wasmGenerationVersion
- criticalDifference

## 6. Manual legacy comparison (validation only)
1. Run manual before/after comparison outside automation pipeline.
2. Classify critical differences using agreed criteria:
   - major global energy divergence
   - dominant hue shift
   - primary detail loss on material region

## 7. Release gate
Release is blocked if any report entry is marked `criticalDifference=true` within the defined scope.
