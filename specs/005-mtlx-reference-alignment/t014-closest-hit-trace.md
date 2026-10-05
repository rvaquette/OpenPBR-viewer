# T014 - Closest-hit branche dans trace()

Date : 2026-10-05. [REQ-001, REQ-003, REQ-007], Plan:6.

## Integration

`main.js` assemble l’ABI et la derivation `closest_hit_mtlx.glsl` uniquement
pour le pathtracer MTLX, sous `REFERENCE_BVH_ENABLED`. Le rasterizer ne recoit
pas ce code et la macro n’est pas definie par le viewer. L’integrateur Three.js
reste la branche par defaut et le backend reference reste `NOT_READY`.

La copie upstream T013 `closest_hit.glsl` reste intacte et byte-identique. La
derivation locale expose les donnees necessaires a `trace()` : Ng geometrique
calcule depuis les aretes monde, Ns par inverse-transpose, tangente, barycentriques,
UV et materialID. `trace()` impose `0 < t < maxDistance`, conserve le hit du sol
et laisse inchanges les chemins locaux Three.js et de shading. Le materialID
brut est transporte ; sa resolution vers le registre MTLX est reportee a T017.

L’AABB utilise un slab test qui traite explicitement les directions paralleles
et les origines dans la boite. Le rayon direction objet n’est pas normalise, ce
qui conserve le parametre t monde. La pile shader est bornee a 64 avec indicateur
de debordement. Avant upload, le packer refuse toute scene pour laquelle la borne
conservative `2 + profondeurTLAS + profondeurBLASmax` depasse 64. Determinant
UV nul : tangente stable de fallback. Les barycentriques tolerent 1e-6 d’erreur
float32 sur les frontieres, sont clampees puis renormalisees ; les hits a t=0
sont exclus.

## Validation

- `reference-trace-integration.test.mjs` compile et link le vrai `trace()` sous
  ESSL 3.00/SwiftShader ; les branches sol et Three.js restent presentes.
- L’oracle `reference-ray-oracle.mjs` execute 10 000 rayons GPU et compare a
  l’intersection CPU brute force : 6 946 hits, 3 054 misses, zero hit/miss ou
  valeur divergente. Sorties comparees : t/maxDistance, P, Ng, Ns, Ts,
  barycentriques, UV et materialID ; erreur absolue max `6.29e-5`.
- La fixture couvre rayon axial/parallel, origine dans bounds, hit rasant,
  backface, segment tronque, UV degeneres, sol et instance a scale negatif.
  Borne pile observee : 4/64 ; un test refuse un depth combine de 65.
- `npm test` : 61/61 PASS ; `npm run build` : PASS ; aucun GL error.
- Smoke du shader de production Three.js : standard-shader-ball, 64x64, 2 spp,
  SwiftShader ; `shaderError=null`, contexte intact, backend Three.js actif.
  Capture/rapport : `artifacts/mtlx-reference-alignment/t014-default-branch-smoke.png`
  et `t014-default-branch-smoke.json`.
- Rapport machine : `artifacts/mtlx-reference-alignment/t014-reference-ray-oracle.json`.

Pas de rendu MTLX distant, pas d’activation runtime ni de changement de shading.
Les ombres/any-hit sont T015/T016 ; l’association materialID-registre est T017.