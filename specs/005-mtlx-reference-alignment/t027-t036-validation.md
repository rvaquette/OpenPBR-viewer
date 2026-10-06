# T027-T036 Validation Status

## T027 Renderer options

Completed. `rendererAdapter` maps supported scene options and rejects unsupported semantics; explicit URL options retain precedence. Four adapter tests pass, the viewer integration contract is covered, and the full build passes. Evidence: `src/scene/rendererAdapter.js`, `tools/mtlx-reference-alignment/renderer-adapter.test.mjs`.

## T028 Lifecycle transitions

Incomplete. Unit tests cover option precedence and sample invalidation hooks. A direct Chrome SwiftShader startup loaded the fixture and compiled shaders, but remained at `samples=0` with `app.loaded=false`; the A -> B -> A sequence therefore did not start. No browser resize or error-and-recovery sequence has been captured. Do not claim the lifecycle gate passed.

## T029-T030 Local denoiser integration

Implementation present: vendored bundle and local weights/notices, Float32 linear RGBA adapter, GUI action/toggle, separate presentation texture, stale-run rejection, and raw accumulation preservation. The 64x64 SwiftShader smoke reached `status=ready` at 16 spp with local `weightsBaseUrl`; denoised and raw PNG hashes differed. The fixture run used `denoiser_backend=cpu` because TFJS WebGL backend initialization is unavailable under this SwiftShader setup. Full lifecycle and image-space/texture validation remain open.

## T031 Quality and linear-radiance validation

Raw MIS convergence passes on the high-dynamic-range fixture: at 64x64, RGB mean is 3.77513 (16 spp), 3.77010 (64 spp), and 3.76991 (256 spp); RMSE against the 256 spp estimate falls from 0.85291 to 0.40893. This confirms convergence for this fixture, not an analytic radiometric oracle or every light-sampling mode.

The denoiser quality gate fails: 16 spp denoised RMSE is 4.77650 (PSNR 19.19 dB), versus raw RMSE 0.85291 (PSNR 34.15 dB). Denoised mean RGB is [1.97718, 1.82089, 1.71908], substantially below the raw/reference mean near 3.77; the denoised maximum is 5.35 versus 43.52 in the 256 spp reference. Keep denoising experimental and do not use its output as validated HDR radiance. Detailed metrics and captures: `artifacts/mtlx-reference-alignment/t031-linear-radiance-quality.json` and the adjacent `denoiser-hdr-*-linear.json` files.

## T032 Runner

The launcher syntax check passes. Headless `--denoise=true` completed at 16 spp and exported raw/denoised output plus linear buffers; `--denoise=false` completed at 64 and 256 spp and exported raw buffers. `--oidn` exits with the explicit obsolete-option error. Full acceptance remains blocked by the T031 quality failure and missing lifecycle/corpus coverage.

## T033-T036 Gates

T033 corpus-wide captures/quality are not complete. T034 is blocked: `D:\platform-tools\adb.exe devices` returned no device, so no Adreno result is claimed. T035 must remain blocked until T028, T031, T033, and T034 gates pass. T036 documentation now records provenance and limitations; external OIDN execution is absent from viewer/runner, but final cleanup remains coupled to the unpassed rollout gates.

## Global Checks

- `node --check launch_render.mjs`: passed.
- `npm test`: 111 passed, 0 failed.
- `npm run build`: passed; Vite CJS API deprecation and large-chunk warnings remain.
- All browser captures above used Chrome ANGLE/Vulkan SwiftShader with `--gpu=false`.
