# T023-T024: Scene Camera and Depth of Field

## Result

Added a CPU camera adapter for `.scene` camera blocks. It interprets 16-value
matrices as row-major, reads translation from indices 3/7/11 and forward from
the third basis column, rebuilds a stable world-up basis, and reports
`CAMERA_ROLL_DROPPED` because the local look-at camera does not retain matrix
roll. Missing camera blocks are framed from local geometry bounds. Explicit
URL options (`camera_position`, `camera_lookat`, `camera_fov`,
`camera_aperture`, `camera_focaldist`) override scene values; absent options
leave scene values authoritative.

The scene FOV is horizontal degrees. The adapter derives the vertical FOV from
the active render aspect; resize updates aspect/FOV without changing pose.
Named scenes continue through their existing camera path.

The pathtracer MTLX shader now samples a lens offset only when aperture is
positive and aims the primary ray at the contract's focal point. Aperture zero
retains the original pinhole origin/direction and does not consume extra RNG
values. DOF controls do not affect secondary bounces or the rasterizer.

## Validation

- `node --test tools/mtlx-reference-alignment/camera-adapter.test.mjs`: 7 passed.
- CPU checks cover 1:1, 16:9 and 9:16 FOV conversion, row-major matrix pose,
  explicit overrides, bounds fallback, stable vertical views, pinhole rays and
  focal-point convergence.
- Static contract verifies DOF uniforms are on the pathtracer material and the
  GLSL samples the lens only for positive aperture.
- `npm test`: 94 passed, 0 failed.
- `npm run build`: passed; existing Vite CJS API deprecation and large-chunk
  warnings remain.
- No browser/GPU render test was run, per user preference. The shader runtime
  compile, visible DOF quality, and distant non-MTLX camera comparison remain
  unverified.