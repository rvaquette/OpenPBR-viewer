# T019-T020: Pure `.scene` Parser and Directive Policy

## Result

Implemented a pure parser in `src/scene/sceneLoader.js`, isolated by
`src/scene/package.json` as an ES module. It returns a scene AST and structured
warnings/errors; it does not fetch resources, invoke MaterialX generation,
publish a viewer scene, or execute either renderer.

The parser policy is checked block-for-block against
`scene-directives.json`. It handles BOM/CRLF, quoted tokens, comments, block
syntax, matrix/TRS values, inline MaterialX as opaque text, material and glTF
material references, and object glob overrides. Unsupported/rejected
directives, duplicate declarations, malformed values, unsafe resource URLs,
invalid source combinations, and unresolved references fail with URL, line,
block, name, and token context where applicable. Adapted options with no local
runtime effect are reported as warnings.

The approved non-MTLX Cornell fixtures from the corpus parse using the pinned
reference root without starting its renderer. The Disney gold witness is
expected to fail on the explicitly rejected `specular` directive.

## Validation

- `node --test tools/mtlx-reference-alignment/scene-loader.test.mjs`: 7 passed.
- `npm test`: 82 passed, 0 failed.
- `npm run build`: passed; existing Vite CJS API deprecation and large-chunk
  warnings remain.
- VS Code diagnostics: no errors in the parser or its test.

T021/T022 remain unstarted. Resource loading, local MaterialX generation,
environment loading, viewer integration, and browser scene publication are not
claimed by this parser milestone.