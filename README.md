# OpenPBR-viewer
An example implementation of the [OpenPBR Surface](https://github.com/AcademySoftwareFoundation/OpenPBR) shading model in a WebGL pathtracer and rasterizer. Includes support for the full OpenPBR v1.2 spec: coat darkening, thin-film iridescence, spectral dispersion, subsurface scattering, fuzz, and more.

Run the live app [here](https://portsmouth.github.io/OpenPBR-viewer).

## Running locally

Install [npm](https://www.npmjs.com/), then:

    npm install

**Development** (with hot-reload):

    npx vite

Then open http://localhost:5173/OpenPBR-viewer in your browser.

**Production build**:

    npm run build
    npm run preview

Then open http://localhost:8080/OpenPBR-viewer in your browser.

## WASM substitution workflow

Run the strict substitution validation pipeline:

    npm run substitution:run

Validate a generated report against the substitution schema:

    npm run substitution:validate-report

Run an ABI quick check on generated GLSL output:

    npm run substitution:check-abi -- --glsl=artifacts/generated.glsl --expectations=public/mtlx/generator-abi-expectations.json

## Strict-failure and ABI troubleshooting

- If generated shading contract validation fails, the runtime enforces explicit failure and does not fallback to legacy BXDF.
- If the rendered output becomes magenta in pathtracer mode, inspect browser logs for substitution failure details.
- Verify required symbols using the ABI checker and `public/mtlx/generator-abi-expectations.json`.
- For manual visual comparison, enable legacy mode explicitly with `?legacy_comparison=true`.

<img src="https://github.com/portsmouth/OpenPBR-viewer/blob/main/images/metal2.png" width="49%"> <img src="https://github.com/portsmouth/OpenPBR-viewer/blob/main/images/absorption.png" width="49%">

<img src="https://github.com/portsmouth/OpenPBR-viewer/blob/main/images/dispersion2.png" width="49%"> <img src="https://github.com/portsmouth/OpenPBR-viewer/blob/main/images/bubbles.png" width="49%">

<img src="https://github.com/portsmouth/OpenPBR-viewer/blob/main/images/honey.png" width="49%"> <img src="https://github.com/portsmouth/OpenPBR-viewer/blob/main/images/subsurface.png" width="49%">

This project uses the [Standard Shader Ball](https://github.com/usd-wg/assets/tree/main/full_assets/StandardShaderBall) asset.

## UI controls:

 - left-click mouse to rotate, right-click mouse to pan camera
 - F key to reset camera to [Standard Shader Ball](https://github.com/usd-wg/assets/tree/main/full_assets/StandardShaderBall) default
 - AWSD keys to fly
 - H key to hide/show the UI
 - P key to save a screenshot of the current render
 - F11 key to enter/exit fullscreen mode