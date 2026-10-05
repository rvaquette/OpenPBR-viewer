# T017 - Registre des materialID de scene

Date : 2026-10-05. [REQ-001, REQ-004, REQ-007], Plan:8.

## Registre et shader

`src/mtlx/referenceMaterialRegistry.js` garde une entree explicite par ID de
scene : `(sceneMaterialID, kind, localMaterialID, parameterVariant, materialKey)`.
Les scene IDs restent des entiers float32 exacts ; aucun `neutralFlag` ne les
remplace. Le registre est borne a 64 entrees, refuse doublons/precision
invalide/IDs absents et verifie la couverture de chaque instance avant publication.

Les enregistrements sont stockes dans des texels RGBA float de `mtlxLightsTex`
apres les lumieres et les blocs de parametres. `main.js` fournit
`window.__openpbrRegisterReferenceMaterialRegistry(scene, records)` : verification
route Pathtracer MTLX, compatibilite du dispatch actif, validation du nombre/type
des parametres, reallocation de texture puis mise a jour des uniforms et reset
d’accumulation. Un document/closure incompatible echoue explicitement.

Le resolver ESSL cherche le sceneMaterialID exact et renvoie kind, localMaterialID
et parameterVariant. Une valeur inconnue invalide le fragment, sans fallback.
`trace()` passe le slot local au pathtracer et positionne le variant utilise par
`mtlxGetMaterialParam`. Variant 0 = valeurs actives, 1 = defaults reserve, 2..63 =
blocs de valeurs explicites pour la meme closure active. Les changements de
dispatch reevaluent le registre contre les descripteurs candidats avant publication.
`TraceShadow` restaure le variant qui etait actif avant son hit auxiliaire.

Limite assumee : un seul dispatch/closure MaterialX local est actuellement actif.
Plusieurs scene IDs peuvent partager cette closure avec des parametres distincts;
des documents necessitant un autre code GLSL ne sont pas approximativement
reduits a ce dispatch et sont rejetes. T018 verifie la fidelite de chaque hook
BSDF/emission/volume ; le loader de scene n’appelle pas encore cette API. Le backend
reference reste dormant.

## Validation

- Tests du helper : IDs distincts, slots props/OpenPBR, coverage, variants differents,
  bool/int/float/vecteurs, capacite/precision et erreurs de dispatch.
- ESSL/WebGL2 relit les texels RGBA : scene IDs 7/19 mappes avec variantes 0/2,
  props 33 vers slot 0, ID 404 absent rejete.
- Smoke `main.js` : enregistrement de deux scene IDs sur le dispatch actif,
  texels reellement publies verifies ; rapport
  `artifacts/mtlx-reference-alignment/t017-material-registration-smoke.json`.
- Oracle GPU/CPU 10 000 rays : zero divergence geometrie, AnyHit, TraceShadow,
  sorties locales et materialID mappe.
- `npm test` : 69/69 PASS ; build PASS ; smoke local MTLX/Three.js et validateur
  documentaire PASS.