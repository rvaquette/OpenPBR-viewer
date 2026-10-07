# T027-T036 Validation Status

## T027 Renderer options

Completed. `rendererAdapter` maps supported scene options and rejects unsupported semantics; explicit URL options retain precedence. Four adapter tests pass, the viewer integration contract is covered, and the full build passes. Evidence: `src/scene/rendererAdapter.js`, `tools/mtlx-reference-alignment/renderer-adapter.test.mjs`.

## T028 Lifecycle transitions

Passed for the renderer-route/resize scope. `node tools/mtlx-reference-alignment/lifecycle-smoke.mjs` uses Chrome ANGLE/Vulkan SwiftShader, `paused=false`, and the local HDR `.scene` fixture. Pathtracer -> Rasterizer -> Pathtracer and resize 96x72 -> 128x80 each reached loaded, non-compiling readiness with at least 2 spp. Scene-load revisions advanced 1 -> 2 -> 3; sample reset revisions advanced 3 -> 6 -> 9 -> 10. Geometry/texture/program counts remained 1/11/4 at every captured state, with no browser errors or context loss. The final render target was 128x80. Captures: `t028-A-pathtracer-initial.png`, `t028-B-rasterizer.png`, `t028-A-pathtracer-return.png`, and `t028-A-pathtracer-resized.png` under `artifacts/mtlx-reference-alignment/`. Machine report: `artifacts/mtlx-reference-alignment/t028-lifecycle-smoke.json`.

This does not claim scene/material/light changes, error-and-recovery, or Adreno coverage; those checks remain open in T033/T034.

## T029 Local package and runtime

Completed. The vendored `denoiser@0.0.11` bundle and Apache-2.0 HDR weights are served locally; the adapter selects `rt_hdr_small`, HDR Float32, and linear input. The runtime smoke dynamically imports the adapter in the Vite-served viewer, executes the real model on a known asymmetric 64x64 RGBA Float32 buffer, and verifies output shape/finiteness, zero/fractional/HDR input components, same-origin weight fetch (HTTP 200), no cross-origin requests, and no browser errors. Results: 16,384/16,384 output components finite; input contained 128 zeros, 9,984 fractional components, and 5,440 components above 1. Weights SHA-256: `c9171947f2bceb4367725b7a0d5b4e0d663ac44108386af42f1b49e4361952e7`. Evidence: `tools/mtlx-reference-alignment/denoiser-runtime-smoke.mjs` and `artifacts/mtlx-reference-alignment/t029-denoiser-runtime.json`.

The smoke uses the TensorFlow.js CPU backend because its WebGL backend is unavailable under this Chrome SwiftShader setup. No CDN or external OIDN executable is used.

## T030 Viewer integration

Completed for viewer wiring, presentation, and camera invalidation. The 64x64/16 spp SwiftShader smoke called the browser denoise action with local weights, confirmed the RGBA32F raw accumulation SHA-256 was identical before and after execution, verified a finite 64x64x4 result, and showed that enabling denoised presentation changes the canvas while disabling it restores the raw canvas hash exactly. A camera drag advanced the reset revision and cleared the stale denoised result. Evidence: `tools/mtlx-reference-alignment/denoiser-integration-smoke.mjs` and `artifacts/mtlx-reference-alignment/t030-denoiser-integration.json`.

This validates integration and lifecycle behavior, not image quality. T031 includes the separate high-radiance stress fixture and balanced material fixtures; see its per-fixture verdict below.

## T031 Quality and linear-radiance validation

Raw MIS convergence passes on the high-dynamic-range fixture: at 64x64, RGB mean is 3.77513 (16 spp), 3.77010 (64 spp), and 3.76991 (256 spp); RMSE against the 256 spp estimate falls from 0.85291 to 0.40893. This confirms convergence for this fixture, not an analytic radiometric oracle or every light-sampling mode.

The actual-model quality sweep uses four local fixtures at 64x64, comparing 16 spp raw/denoised against each same-scene raw 256 spp estimate. The HDR stress fixture keeps quad emission 500; the material-comparison fixtures use emission 50 and ACES presentation so the ground plane is not clipped white in the inspection PNGs. ACES affects display only; the compared buffers remain linear RGBA32F. In the refreshed PNGs, the fraction of pixels with all three RGB bytes above 250 is 0% for brick, 0.12% for emissive marble, 0% for soapbubble, and 0.02% for the HDR stress fixture. The prior white appearance came from the high-emission/no-tonemapping presentation, not a white ground texture.

- HDR quad, emission 500: raw RMSE 0.85291 / 34.15 dB PSNR; denoised 4.77650 / 19.19 dB.
- Brick textures plus normal map, emission 50: raw 0.04023 / 33.37 dB; denoised 0.03144 / 35.51 dB, an improvement on this fixture.
- Emissive marble, emission 50: raw 1.43497 / 29.12 dB; denoised 5.40327 / 17.60 dB.
- Soapbubble transmission and thin-film, emission 50: raw 0.24692 / 33.36 dB; denoised 0.35621 / 30.17 dB.

The denoiser improves the textured brick fixture, but fails the HDR stress, emissive, and transmission/thin-film fixtures; T031's cross-material quality gate therefore remains failed. The fixture quad was calibrated to 50 with ACES for material comparisons, while emission 500 remains in the dedicated HDR stress, also shown with ACES. A reversible exposure sweep at scales 1, 0.5, 0.25, 0.125, and 0.0625 still does not beat raw HDR RMSE; best denoised RMSE is 1.05711 versus raw 0.85291. Do not add exposure scaling or claim global quality success. Keep denoising experimental and do not use its output as validated HDR radiance.

Consolidated report: `artifacts/mtlx-reference-alignment/t031-quality-summary.json`; exposure sweep: `artifacts/mtlx-reference-alignment/t031-denoiser-exposure-sweep.json`. Calibrated linear captures and matching PNGs are under `artifacts/mtlx-reference-alignment/` with `t031-{brick,emissive,transmission-film}50-{16,256}spp` prefixes; HDR-quad evidence remains `t031-linear-radiance-quality.json` and `denoiser-hdr-*-linear.json`.

## T032 Runner

The launcher syntax check passes. Headless `--denoise=true` completed at 16 spp and exported raw/denoised output plus linear buffers; `--denoise=false` completed at 64 and 256 spp and exported raw buffers. `--oidn` exits with the explicit obsolete-option error. Full capture rollout remains blocked by the T031 quality failure and corpus coverage.

## T033 Corpus captures and measurements

Completed local corpus at 64x64/16 spp with `denoise=both`: 16 local cases ran raw and denoised for 32/32 PASS, with per-case GLSL manifests, viewer reports, images, denoised runs retaining their raw PNGs, durations, renderer resource counts, scene mesh/instance/triangle counts, and JS heap measurements. Root report: `artifacts/mtlx-reference-alignment/t033-local-paired-16spp-64x64/report.json`. Reproduce with the paired-capture command in `tools/mtlx-reference-alignment/README.md`.

`bearded-man` raw/denoised both passed at 16 spp: 801,904 triangles, 2 meshes, 0 `InstancedMesh` objects; final heap was approximately 342 MB raw and 359 MB denoised. This local corpus does not contain a true instanced-mesh case, so no instanced draw-path behavior is claimed. These smoke captures do not replace the 128 spp baseline or T031's quality verdict. The full test command reported 114 passes and one unrelated pinned-source-notice hash mismatch in `reference-import.test.mjs`.

## T034 Android / Adreno

The authorized device `R5CW900CHQD` is a Samsung SM-F731B (SM8550, Android 16); SurfaceFlinger and Kiwi both identify Adreno 740 / OpenGL ES 3.2. The T034 soapbubble transmission fixture uses a quad emitter. Two full Kiwi runs reached 64 spp, completed the local denoiser with the raw Float32 SHA-256 unchanged, transitioned Pathtracer -> Rasterizer -> Pathtracer, and resized without context loss. The latest run used the native Kiwi viewport (980x2059 CSS, DPR 2.625) with a bounded 256x256 render target. Its direct ADB screen capture visibly contains the rendered transmission material: `artifacts/mtlx-reference-alignment/t034-adreno/pathtracer-64spp-device.png`.

T034 remains blocked by live Chromium GPU errors. `adb logcat -T 1 -v time chromium:V *:S` ran concurrently with the latest Kiwi smoke and recorded repeated `GL_INVALID_FRAMEBUFFER_OPERATION` errors: incomplete framebuffer attachment with zero size and incomplete draw framebuffer. They did not appear in Playwright's pageerror/console collections, so the harness's runtime result `passed` does not satisfy T034's no-GL-error gate. The time-stamped log is `artifacts/mtlx-reference-alignment/t034-adreno/kiwi-chromium-logcat-20261007-163448.txt`; stderr is empty. The previous Chrome-specific context-loss and black-capture observations are superseded for Kiwi: they reproduced in Chrome but not in either of the two Kiwi runs. Root cause of the zero-size framebuffer errors remains unknown.

Local SwiftShader visual control used the same fixture, HDR environment/irradiance, quad light, 64 spp, 256x256 accumulation target, and Pathtracer MTLX mode (`--gpu=false`). The raw capture `artifacts/mtlx-reference-alignment/t034-local-swiftshader-256-64spp.png` shows both translucent soapbubble lobes with faint cyan/pink reflections; the opaque ground and dark cast shadows dominate, so the bubbles are subtle rather than absent. Linear mean RGB was `[0.3112, 0.3158, 0.3189]`, with 7,990 components above 1 and no non-finite values. With `denoiser_backend=cpu`, the local denoised output `artifacts/mtlx-reference-alignment/t034-local-swiftshader-256-64spp-denoised.png` has the same visible lobes and softens detail, closely matching Kiwi's denoised screen capture. The initial local attempt without explicit `render_size=256x256` used the fixture's 64x64 target and is not the comparison capture. This single-fixture comparison does not override T031's failed cross-material denoiser quality gate.

The T034 harness accepts `T034_CDP_URL` and `T034_EXPECT_PACKAGE` so Kiwi's PID-suffixed DevTools socket can be targeted without using Chrome's socket. Reproduce the live log capture by forwarding that socket to port 9223, running `adb -s R5CW900CHQD logcat -T 1 -v time chromium:V '*:S'` in one terminal, then running `T034_CDP_URL=http://127.0.0.1:9223` and `T034_EXPECT_PACKAGE=com.kiwibrowser.browser` with `node tools/mtlx-reference-alignment/adreno-t034-smoke.mjs` in another. T035 remains blocked by T031 and T034.

T035 remains blocked by T031 and T034. T036 documents provenance and limitations; external OIDN execution is absent from viewer/runner, but final rollout cleanup remains gated.

## Global Checks

- `node --check launch_render.mjs`: passed.
- `npm test`: 114 passed, 1 failed in `reference-import.test.mjs` on a pinned notice hash; unrelated to T033.
- `npm run build`: passed; Vite CJS API deprecation and large-chunk warnings remain.
- All browser captures above used Chrome ANGLE/Vulkan SwiftShader with `--gpu=false`.
