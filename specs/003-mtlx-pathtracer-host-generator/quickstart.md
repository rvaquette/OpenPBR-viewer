# Quickstart - MaterialX Pathtracer Host Generator

## 1. Verify source material
Use the first validation fixture:

```powershell
Test-Path "D:\WebGL2\MaterialX\materials\open_pbr_carpaint.mtlx"
```

Expected: `True`.

## 2. Seed the MTLX pathtracer route
Create the new route from the legacy integrator base:

```powershell
New-Item -ItemType Directory -Force glsl/pathtracing/mtlx
Copy-Item glsl/pathtracing/legacy/pathtracer.glsl glsl/pathtracing/mtlx/pathtracer.glsl
```

Expected: `glsl/pathtracing/mtlx/pathtracer.glsl` exists.

## 3. Add the C++ generator scaffold
Create the new MaterialX-rva generator files:

```text
D:\WebGL2\MaterialX\MaterialX-rva\source\MaterialXGenGlsl\MtlxPathTracerHostShaderGenerator.h
D:\WebGL2\MaterialX\MaterialX-rva\source\MaterialXGenGlsl\MtlxPathTracerHostShaderGenerator.cpp
```

Expected: the new class is separate from `PathTracerGlslShaderGenerator` and follows the host-generation responsibilities of `EsslHostShaderGenerator`.

## 4. Generate dispatch for open_pbr_carpaint
Run the generator wrapper once it exists:

```powershell
node tools/generate-mtlx-pathtracer-dispatch.mjs --mtlx="D:\WebGL2\MaterialX\materials\open_pbr_carpaint.mtlx" --out=glsl/pathtracing/mtlx/generated_bsdf_dispatch.glsl
```

Expected output contains:

```glsl
vec3 evaluateBsdf(...)
vec3 sampleBsdf(...)
```

## 5. Check forbidden legacy dependencies
Run text checks:

```powershell
Select-String -Path glsl/pathtracing/mtlx/*.glsl -Pattern "legacy/|_brdf|_btdf|openpbr_bsdf_evaluate|openpbr_bsdf_sample"
```

Expected: no matches, except comments explicitly documenting forbidden references.

## 6. Build viewer

```powershell
npm run build
```

Expected: Vite build succeeds.

## 7. Compile/render first material
Run a headless compile/render validation after route integration:

```powershell
node launch_render.mjs --headless --browser=edge --mode=Pathtracer --mtlx="D:\WebGL2\MaterialX\materials\open_pbr_carpaint.mtlx" --spp=2 --size=128x128 --output=artifacts/mtlx-pathtracer/open_pbr_carpaint.png
```

Expected: shader compiles, render completes, and no legacy fallback occurs.
