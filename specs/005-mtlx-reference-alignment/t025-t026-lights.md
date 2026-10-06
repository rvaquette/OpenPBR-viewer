# T025-T026: Scene Lights, NEE, Emitters and MIS

## Result

Added `src/scene/lightAdapter.js` to map `.scene` light kinds (quad=0,
sphere=1, distant=2) into the existing local pathtracer types (quad=3,
sphere=4, directional=1). Quad endpoints become `u`/`v`; sphere area/radius,
linear nonnegative emission, distant direction convention, and six-texel
packing are validated. Empty scenes produce a zero sentinel. The local light
records are packed into the light prefix only; existing MaterialX parameter and
material-registry rows retain their established offsets. Point/spot remain
supported local extensions through the existing MTLX light record ABI; v1
`.scene` intentionally accepts only quad/sphere/distant.

For an active `.scene`, its light blocks replace MTLX document lights. Explicit
`mtlx_lights_json` is the only current merge override. A scene disables the
automatic sun while leaving its environment map independent. `hideemitters`
only hides analytic area-light hits on the camera's primary segment.

The local pathtracer now samples quad and sphere lights in NEE, includes their
conditional directional PDFs in `LiPDF`, traces visible quad/sphere emitters
against geometry/ground by nearest distance, and adds emission at camera and
BSDF hits with power-heuristic MIS. Sphere sampling from inside uses the full
sphere and its $1/(4\pi)$ PDF. Point/spot/distant retain delta sampling and
receive unit MIS weight against continuous BSDFs. The local integrator and MTLX
parameter texture remain in place.

## Validation

- `node --test tools/mtlx-reference-alignment/light-adapter.test.mjs`: 7 passed.
- Combined CPU suites for light, camera and scene parser: 21 passed.
- Deterministic CPU MIS convergence: 100,000 samples each for NEE-only,
  BSDF-only and MIS against a numerical Lambertian/quad integral. All three
  means are within 1.5%; MIS variance is below BSDF-only.
- `npm test` on SwiftShader: 101 passed, 0 failed. The isolated ESSL trace/any-hit
  compile/link tests and the local `TraceShadow` fragment test passed.
- Headless Pathtracer MTLX smoke on Chrome SwiftShader, 64x64, 64 spp,
  `skyPower=0`: `.scene` loaded quad/sphere/distant as local types 3/4/1,
  `mtlxLightCount=3`, shader ready with no error/context loss. Capture and report:
  `artifacts/mtlx-reference-alignment/t025-t026-lights-swiftshader-64spp.png`
  and `artifacts/mtlx-reference-alignment/t025-t026-lights-swiftshader-64spp.json`.
- NEE-only, BSDF-only and MIS each compiled/rendered headless under SwiftShader
  at 64x64/64 spp. Display-space RGB means: 51.18, 41.34 and 51.23/255;
  NEE/MIS agree, while BSDF-only is low at this budget. At 256 spp BSDF-only
  reaches 50.51/255, close to the 64 spp NEE/MIS means; this is a display-space
  smoke comparison, not calibrated linear-energy proof. Reports/captures are
  `mis-{nee,bsdf,mis}-swiftshader.{json,png}` and
  `mis-bsdf-swiftshader-256spp.{json,png}`.
- `node --test --test-name-pattern="trace\\(\\) selects" tools/mtlx-reference-alignment/reference-trace-integration.test.mjs`: static BVH-only assertion passed.
- `npm run build`: passed; existing Vite CJS API deprecation and large-chunk warnings remain.
- `get_errors`: no diagnostics in touched source/test files.
- The CPU analytic convergence/variance comparison and headless GPU mode
  comparison passed as described above. A separate 64x64 high-dynamic-range
  MIS fixture was captured at 16/64/256 spp with Float32 linear-radiance export.
  RGB means were 3.77513/3.77010/3.76991; RMSE against 256 spp fell from
  0.85291 at 16 spp to 0.40893 at 64 spp. This validates sampled convergence
  for that fixture, not an analytic radiometric oracle or every sampling mode.
  Full metrics: `artifacts/mtlx-reference-alignment/t031-linear-radiance-quality.json`.
- GPU texture readback, isolated per-light distance/orientation/backface/hideemitters
  comparisons, and calibrated per-mode analytic GPU energy remain unverified.
- The full Pathtracer MTLX scene shader did compile and render under SwiftShader;
  that smoke is not an analytic energy/convergence comparison.