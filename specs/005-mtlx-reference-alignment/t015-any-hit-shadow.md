# T015 - Any-hit et TraceShadow

Date : 2026-10-05. [REQ-001, REQ-003, REQ-007], Plan:7.

## Port et branchement

`glsl/pathtracing/mtlx/reference/anyhit.glsl` est la copie byte-identique
d’upstream, SHA-256 `e4ff7cdd408cb550ebddd4e8d4baacc33bd2efdda8b906e2ff3bf7ca9cde915d`,
avec notice MIT Asif Ali 2019. La derivation `anyhit_mtlx.glsl` suit les textures
RGBA avec ABI logique RGB, garde le rayon objet non normalise, respecte
`0 < t < maxDistance`, traite determinant nul et barycentriques proches des
aretes, et verifie pile/sentinelles.

Sous `REFERENCE_BVH_ENABLED`, `TraceShadow` utilise AnyHit pour l’occlusion
geometrique. Il conserve `trace()` pour l’intersection du sol et l’identification
du materiau, puis garde le filtre local opaque/thin-walled. Sans hit BVH et sol
desactive, il retourne visible sans parcours closest-hit. Aucune alpha-test ou
texture materiau de la reference n’est importee. La macro reste non definie dans
le viewer, dont le backend actif reste Three.js.

## Validation

- Hash/notice/import raw upstream verifies par `reference-closest-hit.test.mjs`.
- Le vrai `AnyHit`, `trace()` et `TraceShadow` compilent/linkent ensemble en ESSL
  3.00 WebGL2/SwiftShader.
- Oracle GPU/CPU sur 10 000 rays : zero divergence AnyHit geometrique et zero
  divergence de visibilite TraceShadow, sol inclus. Les segments limites
  comprennent des blockers au-dela de maxDistance et des surfaces successives.
- `npm test` : 62/62 PASS ; build et validateur documentaire PASS.
- Smoke pathtracer MTLX local : standard-shader-ball, 64x64, 2 spp, SwiftShader ;
  `shaderError=null`, contexte intact, backend Three.js actif.
- Capture/rapport : `artifacts/mtlx-reference-alignment/t015-default-branch-smoke.png`
  et `t015-default-branch-smoke.json`.
- Rapport : `artifacts/mtlx-reference-alignment/t015-shadow-oracle.json`.

Le filtre thin-walled detaille et sa resolution par materialID dependent de T016/T017 ;
l’oracle T015 utilise le chemin opaque. Pas de rendu distant ni d’activation runtime.