# T018 - Hooks de shading par variant

Date : 2026-10-05. [REQ-001, REQ-004, REQ-007], Plan:8.

## Hooks variant-aware

Toutes les declarations du bloc GLSL `__MTLX_PARAMS_BEGIN__` sont maintenant
table-backed, y compris celles sans metadonnees UI ; seules les valeurs exposees
dans le document restent visibles dans le GUI. Chaque variant garde le meme
schema ordonne `(nom,type)` que la closure active. Une reconfiguration dont le
schema diverge du registre est rejetee avant publication.

Les wrappers opaque/thin-walled lisent le variant courant, sans utiliser le
`g_ptOpacity` potentiellement stale avant `prepare()`. `TraceShadow` appelle
`mtlx_openpbr_prepare` sur le bloqueur avant les filtres, puis restaure le variant
de la surface eclairee. Evaluate/sample, opacity, thin-walled, transmission,
roughness, IOR, thin-film, emission HostEval et sorties `internal_medium` utilisent
les memes accesseurs `mtlxGetMaterialParam` du variant.

Volume, dispersion et thin-film possedent des defines de compilation :
`validateMtlxVariantFeatures` refuse toute variante qui requiert un define absent,
au lieu d’ignorer silencieusement la closure. Les variantes a code GLSL different
restent hors contrat ; un seul dispatch local actif peut etre partage par IDs.

## Validation

- Tests hooks : opacity avant prepare, thin-walled, transmission, roughness,
  IOR/film, emission et guards de defines ; valeurs scalaires/vecteurs/bool.
- Smoke navigateur sur le dispatch WASM local Honey, avec `VOLUME_ENABLED=true` :
  IDs 7/19, variants 0/2, transmission weight/depth/scatter, thin-walled, emission
  couleur/luminance. Les blocs dispersion et thin-film sont rejetes car leurs
  defines ne sont pas compiles. Le shader genere compile sans erreur.
- L’oracle GPU/CPU final : 10 000 rayons, zero divergence closest-hit, AnyHit,
  TraceShadow et materialID local ; erreur geometrie maximale `6.29e-5`.
- `npm test` : 75/75 PASS ; `npm run build` : PASS.
- Smoke/dispatch : `artifacts/mtlx-reference-alignment/t018-material-hooks-smoke.json`
  et `t018-dispatch-smoke.json`.

Limite : plusieurs IDs partagent une seule closure locale par dispatch ; un
document necessitant un autre code shader est refuse. Le loader `.scene` ne
publie pas encore de registre ; backend reference toujours dormant.