# Validation Corpus Contract

## Purpose
Define the fixture corpus required to prove first-delivery support for all selected MaterialX material models.

## Required Carpaint Fixtures
Source directory: `D:\WebGL2\MaterialX\materials`

```text
open_pbr_carpaint.mtlx
standard_surface_carpaint.mtlx
disney_principled_carpaint.mtlx
gltf_pbr_carpaint.mtlx
usd_preview_surface_carpaint.mtlx
```

## Required Synthetic Fixtures
Synthetic fixtures may be generated under:

```text
artifacts/mtlx-pathtracer/fixtures/
```

Required synthetic material models:
- `open_pbr_surface`
- `standard_surface`
- `disney_principled`
- `gltf_pbr`
- `usd_preview_surface`

## Fixture Metadata
Each fixture must record:
- fixtureId
- fixtureType (`carpaint` or `synthetic`)
- materialModel
- sourceMtlxPath
- generatedDispatchPath

## Validation Output
Validation reports must distinguish carpaint failures from synthetic failures and must include:
- generationStatus
- legacyDependencyCheckStatus
- viewerCompileStatus
- failureCause when any status fails

## Completion Rule
The feature is not validation-complete until every carpaint and synthetic fixture has a generated dispatch artifact and a passing validation record.