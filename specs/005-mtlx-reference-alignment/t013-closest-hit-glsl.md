# T013 - Port source du closest-hit GLSL

Date : 2026-10-05. [REQ-001, REQ-003, REQ-007], Plan:6.

## Port

`glsl/pathtracing/mtlx/reference/closest_hit.glsl` reprend sans modification
`D:/WebGL2/GLSL-PathTracer-JS/shaders/common/closest_hit.glsl`. SHA-256 upstream
et local : `864af40b7f85ae4f08c4207231c286c816f41805552f3d183543b17ef329b70b`,
conforme au hash deja epingle par T001. La notice MIT Asif Ali 2019 est conservee.

`glsl-sources.js` expose le texte comme `glsl_mtlx_reference_closest_hit` via
`?raw`, avec les autres sources GLSL. La fonction conserve les noms/types ABI
upstream (Ray, State, LightSampleRec, BVH, topBVHIndex et samplers). Les wrappers
texelFetch et les structs requis sont fournis par l’hote du futur port, pas
dupliques dans ce fichier.

## Validation et limites

- `npm test` : 56/56 PASS, dont le test du hash pinne, de la notice et de
  l’import/export raw.
- `node tools/mtlx-reference-alignment/closest-hit-compile-smoke.mjs` :
  compilation fragment et link ESSL 3.00 WebGL2/SwiftShader PASS avec un harness
  d’ABI minimal (wrappers sampler 2D, structs et uniform topBVHIndex).
- `npm run build` : PASS ; seuls les avertissements Vite CJS et taille de chunk
  deja presents sont emis.
- Aucun changement du pathtracer MTLX actif, de `trace()`, du GLSL local ou du
  shading ; aucun renderer distant ni rendu MTLX execute.

Cette tache ne prouve ni la fidelite comportementale GPU/CPU, ni les cas
numeriques du contrat. Le raccord a `trace()`, le respect de `maxDistance`, les
oracles de rayons et les capacites de pile restent a T014. Le backend de
production demeure Three.js et `referenceReady=false`.