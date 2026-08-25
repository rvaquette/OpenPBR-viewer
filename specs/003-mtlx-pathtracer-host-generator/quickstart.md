# Quickstart - MaterialX Pathtracer Host Generator

## 1. Verify carpaint source materials

```powershell
$materials = @(
	"D:\WebGL2\MaterialX\materials\open_pbr_carpaint.mtlx",
	"D:\WebGL2\MaterialX\materials\standard_surface_carpaint.mtlx",
	"D:\WebGL2\MaterialX\materials\disney_principled_carpaint.mtlx",
	"D:\WebGL2\MaterialX\materials\gltf_pbr_carpaint.mtlx",
	"D:\WebGL2\MaterialX\materials\usd_preview_surface_carpaint.mtlx"
)
$materials | ForEach-Object { "$_ = $(Test-Path $_)" }
```

Expected: all entries return `True`.

## 2. Seed the MTLX pathtracer route

```powershell
New-Item -ItemType Directory -Force glsl/pathtracing/mtlx/generated
Copy-Item glsl/pathtracing/legacy/pathtracer.glsl glsl/pathtracing/mtlx/pathtracer.glsl
```

Expected: `glsl/pathtracing/mtlx/pathtracer.glsl` exists.

## 3. Create synthetic fixtures

Generate one simple `.mtlx` fixture per required model into:

```text
artifacts/mtlx-pathtracer/fixtures/
```

Expected fixture types:
- `open_pbr_surface`
- `standard_surface`
- `disney_principled`
- `gltf_pbr`
- `usd_preview_surface`

## 4. Add the C++ generator scaffold

Create the new MaterialX-rva generator files:

```text
D:\WebGL2\MaterialX\MaterialX-rva\source\MaterialXGenGlsl\MtlxPathTracerHostShaderGenerator.h
D:\WebGL2\MaterialX\MaterialX-rva\source\MaterialXGenGlsl\MtlxPathTracerHostShaderGenerator.cpp
```

Expected: the new class is separate from `PathTracerGlslShaderGenerator` and follows the host-generation responsibilities of `EsslHostShaderGenerator`.

## 5. Generate per-material dispatch artifacts

Example for one fixture:

```powershell
node tools/generate-mtlx-pathtracer-dispatch.mjs --mtlx="D:\WebGL2\MaterialX\materials\open_pbr_carpaint.mtlx" --out=glsl/pathtracing/mtlx/generated/open_pbr_carpaint/generated_bsdf_dispatch.glsl
```

Repeat for all carpaint and synthetic fixtures.

Expected output contains:

```glsl
vec3 evaluateBsdf(...)
vec3 sampleBsdf(...)
```

## 6. Check forbidden dependencies

```powershell
Select-String -Path glsl/pathtracing/mtlx/**/*.glsl -Pattern "legacy/|_brdf|_btdf|openpbr_bsdf_evaluate|openpbr_bsdf_sample|PathTracerGlslShaderGenerator"
```

Expected: no implementation matches, except comments explicitly documenting forbidden references.

## 7. Build viewer

```powershell
npm run build
```

Expected: Vite build succeeds.

## 8. Compile/render validation corpus

Run one headless compile/render validation per fixture after route integration:

```powershell
node launch_render.mjs --headless --browser=edge --mode=Pathtracer --mtlx="D:\WebGL2\MaterialX\materials\open_pbr_carpaint.mtlx" --spp=2 --size=128x128 --output=artifacts/mtlx-pathtracer/validation/open_pbr_carpaint.png
```

Expected: every fixture compiles/renders or fails explicitly with diagnostics; no legacy fallback and no generic approximation path occurs.
