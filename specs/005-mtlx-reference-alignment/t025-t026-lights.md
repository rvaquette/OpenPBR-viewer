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

- `node --test tools/mtlx-reference-alignment/light-adapter.test.mjs`: 6 passed.
- Combined CPU suites for light, camera and scene parser: 20 passed.
- `npm test` on SwiftShader: 100 passed, 0 failed. The isolated ESSL trace/any-hit
  compile/link tests and the local `TraceShadow` fragment test passed.
- `node --test --test-name-pattern="trace\\(\\) selects" tools/mtlx-reference-alignment/reference-trace-integration.test.mjs`: static BVH-only assertion passed.
- `npm run build`: passed; existing Vite CJS API deprecation and large-chunk warnings remain.
- `get_errors`: no diagnostics in touched source/test files.
- No full scene render was run. GPU texture readback, NEE renders, visible
  emitter renders, and convergence/MIS energy comparison remain unverified.
- The isolated ESSL checks do not compile the full pathtracer material dispatch;
  full scene shader integration and rendered light energy remain unverified.