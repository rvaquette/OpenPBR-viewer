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

The generator wrapper drives `MtlxPathTracerHostShaderGenerator` (compiled to WASM in
`public/mtlx/`) and writes to the deterministic path
`glsl/pathtracing/mtlx/generated/<material-id>/generated_bsdf_dispatch.glsl`.

Carpaint fixtures (MaterialX-rva examples) + synthetic fixtures:

```powershell
$base = "D:\WebGL2\MaterialX\MaterialX-rva\resources\Materials\Examples"
$carpaint = @(
	"OpenPbr\open_pbr_carpaint.mtlx",
	"StandardSurface\standard_surface_carpaint.mtlx",
	"DisneyPrincipled\disney_principled_carpaint.mtlx",
	"GltfPbr\gltf_pbr_carpaint.mtlx",
	"UsdPreviewSurface\usd_preview_surface_carpaint.mtlx"
)
foreach ($f in $carpaint) { node tools/generate-mtlx-pathtracer-dispatch.mjs --mtlx="$(Join-Path $base $f)" }

$synthetic = @("open_pbr_surface","standard_surface","disney_principled","gltf_pbr","usd_preview_surface")
foreach ($m in $synthetic) { node tools/generate-mtlx-pathtracer-dispatch.mjs --mtlx="$PWD\artifacts\mtlx-pathtracer\fixtures\synthetic_$m.mtlx" }
```

Each invocation prints `{ "materialId": ..., "out": ..., "ok": true }` and the output contains:

```glsl
vec3 evaluateBsdf(...)
vec3 sampleBsdf(...)
```

## 6. Validate the corpus (text checks + no forbidden dependencies)

```powershell
node tools/validate-mtlx-pathtracer-corpus.mjs
```

Expected: `ok: true`, `carpaint` and `synthetic` each `total 5 / passed 5 / failed 0`.
The report at `artifacts/mtlx-pathtracer/validation/report.json` records, per fixture,
`generationStatus`, `legacyDependencyCheckStatus`, and `viewerCompileStatus`, plus a
top-level `guarantees` object (`noLegacyFallback`, `noGenericApproximation`).

### 6a. Forbidden `PathTracerGlslShaderGenerator` dependency check

The MTLX route and generated artifacts must never depend on
`PathTracerGlslShaderGenerator`.

```powershell
# Generated dispatch artifacts (code only; comments documenting the ban are OK):
Select-String -Path glsl/pathtracing/mtlx/generated/**/*.glsl -Pattern "PathTracerGlslShaderGenerator"
# Runtime route assembly:
Select-String -Path main.js -Pattern "PathTracerGlslShaderGenerator"
```

Expected: no matches in generated artifacts; in `main.js` the only match is inside
`generateMtlxGlsl` (the separate substitution path), never in `generateMtlxRouteDispatch`
or `assemble_mtlx_route_dispatch`.

### 6b. Forbidden legacy `_brdf` / `_btdf` dependency check

```powershell
Select-String -Path glsl/pathtracing/mtlx/generated/**/*.glsl `
	-Pattern "pathtracing/legacy/|\b(coat|diffuse|fuzz|metal|specular)_brdf\b|\b(diffuse|specular)_btdf\b|\bopenpbr_bsdf_(evaluate|sample)\b"
```

Expected: no matches (the generated dispatch uses only MaterialX `mx_*` closures).
The authoritative gate is `node tools/validate-mtlx-pathtracer-corpus.mjs`
(`legacyDependencyCheckStatus = success` for all 10 fixtures).

## 7. Build viewer

```powershell
npm run build
```

Expected: Vite build succeeds (`built in ...`).

## 8. Compile/render validation corpus (MTLX route)

The `--mode=mtlx` alias selects the `Pathtracer MTLX` route, which assembles the
generated per-material dispatch (renamed `mtlxGen*`) behind the integrator's
`mtlx_openpbr_*` hooks. A successful run writes `render_<material-id>.png`.

```powershell
# One carpaint example (SwiftShader, deterministic):
node launch_render.mjs --headless --start-server --mode=mtlx --gpu=false `
	--mtlx="D:\WebGL2\MaterialX\MaterialX-rva\resources\Materials\Examples\OpenPbr\open_pbr_carpaint.mtlx" `
	--spp=4 --size=128x128 --output=artifacts/mtlx-pathtracer/validation/render_open_pbr_carpaint.png
```

Loop over all carpaint + synthetic fixtures with the same command shape (use absolute
`--mtlx` paths). Expected: each fixture reaches `spp atteints` and writes its PNG, or
fails explicitly with a GLSL diagnostic; there is no legacy fallback and no generic
approximation path.

## 9. Validated outcomes

- Generator: all five models generate a self-contained `evaluateBsdf`/`sampleBsdf`
  dispatch (params folded as literals; dielectric transmission lobe with GGX refraction
  + Beer-Lambert extinction).
- Corpus text checks: 5 carpaint + 5 synthetic, `passed 10 / failed 0`, no forbidden
  legacy or `PathTracerGlslShaderGenerator` references.
- Viewer route: 10/10 fixtures compile and render through the generated-dispatch MTLX
  route (`viewerRendered 5/5` carpaint and synthetic).
- Guarantees: `noLegacyFallback = true`, `noGenericApproximation = true` — the route
  throws if the generated dispatch is missing, and the generator throws on unsupported
  or incomplete materials.

