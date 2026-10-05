# T006 - Runner TS et backend explicite

Date : 2026-10-05. Verdict : PASS. Backend reference non active.

## Configuration

tsx 4.20.6 verrouille dans package.json/package-lock.json, Node >=18.
Configuration tools/mtlx-reference-alignment/tsconfig.json : ES2022, resolution
Bundler, noEmit, strict=false pour rester compatible avec les sources upstream.
Le runner transpile et execute les TS ; un typecheck tsc complet n'est pas revendique.

```powershell
npm test
npm run test:bvh-reference
```

npm test inclut les tests .mjs existants et les tests .ts directs des modules BVH.
Les imports .js upstream sont resolus vers les .ts locaux. Aucun moteur distant
n'est importe par les tests TS. Le backend.mjs est explicitement ESM, sans changer
le format global du paquet existant.

## Contrat runtime

main.js accepte bvh_backend=threejs|reference dans l'URL ; defaut threejs.
La validation precede la generation du dispatch et est repetee a buildBvh.
src/bvh/backend.mjs conserve Three.js comme seul backend pret :

- reference + Pathtracer MTLX -> BVH_BACKEND_NOT_READY, pas de fallback silencieux.
- reference + autre route -> BVH_BACKEND_ROUTE_UNSUPPORTED.
- nom inconnu/obsolete -> BVH_BACKEND_UNKNOWN.

window.__openpbrBvhBackend expose requested/active/available/referenceReady/error.
Le rapport de capture conserve cet etat, y compris pour le refus attendu.
Aucun import des modules reference dans main.js, aucune modification du GLSL.
Pas de controle GUI reference activable tant que son implementation n'est pas prete.

## Verification

- npm test : 19 tests passes, 0 echec ; incluant deux tests TS directs.
- npm run build : PASS ; avertissements Vite preexistants.
- Smoke local Disney Gold 256x256/128 SPP, SwiftShader : PASS ; active=threejs.
  Pixels RGB identiques a la baseline T004, pas seulement similaires.
- Refus reference teste en navigateur : exit 1 attendu, BVH_BACKEND_NOT_READY,
  active=null, dispatchBytes=0 et aucune image de fallback.

Preuves : artifacts/mtlx-reference-alignment/t006-backend-smoke/report.json et
t006-backend-rejection/viewer.json. Les sorties d'echec attendues ne sont pas
declarees comme captures PASS ; elles prouvent la validation de configuration.

L'installation npm signale 9 vulnerabilites (1 low, 3 moderate, 5 high).
Pas de npm audit fix/force ni de mise a jour hors perimetre. Ce point reste a traiter
separement ; aucun avis de securite global n'est donne par les tests T006.

T006 et jalon 2 termines. Construction des adaptateurs et oracle de rayons restent
T007 et suivantes ; referenceReady reste false jusqu'a leur integration validee.