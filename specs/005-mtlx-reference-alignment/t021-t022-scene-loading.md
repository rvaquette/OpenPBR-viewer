# T021-T022: Local `.scene` Resource Loading

## Result

Added `scene_url` loading while preserving the named-scene path. The scene
adapter resolves the scene document, MaterialX documents and geometry/envmap
resources against their owning URLs; only credential-free HTTP(S) URLs are
accepted. It loads `.gltf`/`.glb` through Three.js `GLTFLoader`, checks object
glob overrides against loaded names, applies row-major scene matrices or TRS,
and prepares world-space merged geometry. Unsupported mesh extensions,
unbound/non-MaterialX materials and multiple active scene materials fail
explicitly; no approximate Disney conversion or silent material fallback is
used. MaterialX generation uses the viewer's local WASM generator.

Scene candidates are revision-checked before publication. Superseded or failed
loads dispose their candidate resources; leaving `scene_url` for a named scene
also releases its geometry, envmaps and ground texture. `launch_render.mjs`
accepts `--scene_url` and waits for the scene's loaded signal after navigation.

The active viewer route has one MaterialX closure. Scenes requiring distinct
closures, non-MaterialX BSDF bindings, or non-glTF geometry are rejected until
their dedicated adapter/runtime tasks exist. Camera/light/renderer directive
application is also left for later tasks.

## Validation

- `npm test`: 87 passed, 0 failed.
- `node --test tools/mtlx-reference-alignment/reference-scene-adapter.test.mjs`: 5 passed.
- `npm run build`: passed. Existing Vite CJS API deprecation and large-chunk warnings remain.
- Headless runner, SwiftShader, Rasterizer MTLX, 128x128, 2 spp:
  `node launch_render.mjs --mode="Rasterizer MTLX" --gpu=false --denoise=false --headless=true --scene_url=/scene-url-smoke/scene.scene --spp=2 --max_samples=2 --size=128x128 --render_size=128x128 --port=5181 --start-server --output=artifacts/mtlx-reference-alignment/t021-t022-scene-url-raster-smoke.png --report=artifacts/mtlx-reference-alignment/t021-t022-scene-url-raster-smoke.json`
- Report confirms `ready=true`, `samples=2`, no shader error/context loss,
  `scene.status=loaded`, and 46,704 triangles. The local MTLX dispatch was
  present (99,972 bytes); Vite was stopped by the runner after capture.
- Pathtracer MTLX SwiftShader compilation did not reach readiness within the
  attempt and is not claimed as validated; the raster route is the passing
  browser smoke for this milestone.

T023/T024 camera and depth-of-field behavior, T025/T026 light parsing/shading,
and T027/T028 renderer-option/lifecycle behavior remain unstarted.