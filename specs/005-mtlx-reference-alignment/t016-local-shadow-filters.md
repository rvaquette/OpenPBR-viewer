# T016 - Filtres locaux d’ombre

Date : 2026-10-05. [REQ-001, REQ-003, REQ-007], Plan:7.

## Regles conservees

`TraceShadow` garde la politique locale : un miss est visible ; un hit bloque,
sauf un hit `MATERIAL_OPENPBR` dont le materiau courant est non opaque et
thin-walled. Les hits props et sol restent bloquants. Le test WebGL2
`shadow-filter.test.mjs` execute le vrai `TraceShadow` extrait du shader pour
ces six cas : miss, OpenPBR opaque, OpenPBR thin-walled, OpenPBR non-thin-walled,
props et sol.

Dans la derivation `anyhit_mtlx.glsl`, seule l’intersection geometrique decide
l’occlusion. Les blocs `OPT_ALPHA_TEST`, `materialsTex`, `textureMapsArrayTex`,
`OPT_LIGHTS` et `OPT_RAYMARCHING` upstream ont ete retires ; aucune alpha mask
ou texture/atlas distant n’est consulte. `reference-trace-integration.test.mjs`
verrouille cette absence. La branche de reference appelle ensuite `trace()` pour
conserver les regles locales de sol et de materiau.

## Validation et limites

- Le shader de regles locales compile et passe les six valeurs attendues.
- L’oracle GPU/CPU AnyHit + TraceShadow : 10 000 rays, zero divergence ; segments
  tronques, surfaces successives et sol inclus.
- `npm test` : 63/63 PASS ; `npm run build` et le validateur documentaire PASS.
- Smoke Three.js/MTLX 64x64, 2 spp : shader sans erreur, contexte intact.
- Capture/rapport : `artifacts/mtlx-reference-alignment/t016-default-branch-smoke.png`
  et `t016-default-branch-smoke.json`.

Le test local prouve la politique pour `MATERIAL_OPENPBR`; les IDs bruts d’une
scene reference ne sont pas encore resolus vers ce registre. Cette responsabilite
est T017. Le backend reste dormant et aucun rendu MTLX distant n’est utilise.