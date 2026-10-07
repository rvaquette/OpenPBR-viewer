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

## T033-T036 Gates

T033 corpus-wide captures/quality are not complete. T034 is blocked: `D:\platform-tools\adb.exe devices` returned no device, so no Adreno result is claimed. T035 must remain blocked until T031, T033, and T034 gates pass. T036 documentation now records provenance and limitations; external OIDN execution is absent from viewer/runner, but final cleanup remains coupled to the unpassed rollout gates.

## Global Checks

- `node --check launch_render.mjs`: passed.
- `npm test`: 112 passed, 0 failed.
- `npm run build`: passed; Vite CJS API deprecation and large-chunk warnings remain.
- All browser captures above used Chrome ANGLE/Vulkan SwiftShader with `--gpu=false`.
