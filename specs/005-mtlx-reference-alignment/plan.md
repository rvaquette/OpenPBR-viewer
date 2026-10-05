# Rapprochement du pathtracer MTLX avec la reference

Date : 2026-10-04. Statut au 2026-10-05 : jalons 0 a 7 valides ; T013-T017
closest/any-hit et registre materialID termines sous macro dormante. Backend reference non active.
Reference : D:/WebGL2/GLSL-PathTracer-JS, notamment src/core/pathtracer/.

## Contraintes

- REQ-001 : conserver au maximum le GLSL, le generateur WASM et le rendu MTLX locaux.
- REQ-002 : reprendre le calcul BVH TS complet, BLAS/TLAS, instances et traduction GPU.
- REQ-003 : reprendre le parcours GLSL des textures BVH, closest-hit et any-hit.
- REQ-004 : reprendre le loader .scene, ressources, transforms et affectations materiaux.
- REQ-005 : transmettre camera, FOV, aperture et focalDist au GLSL local.
- REQ-006 : transmettre et integrer les lumieres dans le pathtracer local.
- REQ-007 : un controle bloquant entre chaque etape, avec preuves conservees.
- REQ-008 : reprendre le denoiser du pathtracer distant et supprimer l'utilisation
   du denoiser externe OIDN dans le viewer et les captures automatisees.

Le renderer distant est autorise uniquement en pathtracer NON-MTLX. Son rendu MTLX
ne fonctionne pas : ne pas le lancer, importer son generateur, ses closures ou utiliser
ses images. Son mode non-MTLX peut controler geometrie/camera/lumieres sur fixtures
simples, sans exiger des images identiques aux materiaux MTLX locaux.

Conserver integrateur local, hooks mtlx_openpbr_*, volumes/transmission/thin-film,
samplers nommes MTLX, sol, accumulation, compilation asynchrone et warm-up.
Ne pas reprendre globalement skeleton/pathtrace, BSDF distants, rendu tuile, atlas,
ou WebGPU. Reprendre le denoiser distant separement du renderer et de son pipeline MTLX.
Ne pas activer le CDF envmap local desactive pour regression connue.
Scenes precompilees/sceneWithDataLoader hors perimetre. Toute directive non supportee
est diagnostiquee, jamais ignoree silencieusement.

## Sources et architecture

Reprendre src/bvh/{bbox,bvh,splitBvh,bvhTranslator}.ts, dependances math utiles,
construction des maillages de src/core/mesh.ts, BLAS/TLAS de PathtracerScene et formats
d'upload de PathtracerRenderer. Ces dependances depassent src/core/pathtracer/.
Conserver les algorithmes en TS, consommes par Vite ; ajouter un runner TS explicite
pour Node. Adapter les frontieres plutot que reecrire les algorithmes.

Destinations proposees : src/bvh/reference/ (TS/math), referenceSceneAdapter.js et
referenceGpuAdapter.js sous src/bvh/ ; sceneLoader.js, referenceSceneAdapter.js,
cameraAdapter.js et lightAdapter.js sous src/scene/ ; GLSL repris sous
glsl/pathtracing/mtlx/reference/, importe via glsl-sources.js avec ?raw.
Tests regroupes sous tools/mtlx-reference-alignment/, petites fixtures sous
public/reference-alignment/, preuves sous artifacts/mtlx-reference-alignment/.

Denoiser : reprendre `src/external/denoiser/denoiser.js` distant, ses ressources de
modele et notices dans `src/denoiser/reference/` et, si necessaire, `public/denoiser/`.
Ajouter `src/denoiser/referenceDenoiserAdapter.js` pour le cycle de vie et les buffers
du viewer, sans importer PathtracerRenderer. Le bundle inspecte inclut TensorFlow.js :
supprimer l'executable externe ne signifie pas supprimer toutes les dependances tierces.
Figer versions, hashes, licences, poids et URLs ; servir les ressources localement,
sans dependance obligatoire a un CDN ou a une installation OIDN.
API observee : onBackendReady, setInputData('color', Float32Array), execute,
onExecute(..., 'float32'), abort et dispose. Le distant utilise un backend WebGL,
un canvas dedie, un verrou d'execution et une texture de presentation separee.
Son branchement inspecte ecrete les entrees a [0,1] : ne pas reprendre ce comportement
sur la radiance HDR sans figer et tester le contrat couleur/hdr/srgb du modele.

Le local utilise actuellement MeshBVH via main.js/src/bvh-compat.js ; src/bvh/ est
vide. Ne pas considerer l'ancien port natif comme une base validee.
Le local fusionne ses geometries ; la reference utilise BLAS par mesh et TLAS par
instance. Remplacer le flag neutre/MTLX par une correspondance materialID explicite.
Preserver UV, normales geometriques/shading et tangentes/orientation locales.
Interface vers trace() : t, position monde, Ng, Ns, tangente, UV, barycentriques,
triangleID, instanceID et materialID. Pas de remplacement du shading par State distant.

Backend Three.js conserve temporairement comme temoin A/B pour Pathtracer MTLX,
selection explicite et sans fallback automatique. Rasterizer MTLX/legacy inchanges.
Lumieres : enums locaux point=0/directional=1/spot=2/quad=3 ; reference
rect=0/sphere=1/distant=2/point=3/spot=4. Mapper, ne pas copier les nombres.
Reference : 15 floats logiques/lumiere et 5 texels RGB ; local : 6 vec4/lumiere.
Le loader inspecte parse quad/sphere/distant, pas point/spot : extensions explicites.

## Controles transversaux

Un echec bloque l'etape suivante : corriger et relancer le meme controle.
Rapport par jalon : revision/hashes, configuration, commande, attendu/obtenu,
assertions, captures et verdict PASS/FAIL. Controle manuel = checklist et capture.
Oracle shading : local avant migration. Oracle geometrie : triangles CPU exhaustifs
independants du BVH, modules TS isoles et renderer distant NON-MTLX si utile.
Oracle parsing/packing : donnees et code distant, sans execution du pipeline MTLX.

Au moins 10 000 rayons fixes incluant des hits ; hit/miss identique, erreur t <=
1e-4*max(1,abs(t)), barycentriques <= 1e-4. Figer tolerances au jalon 1 et traiter
explicitement les ties d'aretes partagees. Probes GPU pour t/UV/normales/IDs.
Images locales A/B : memes camera/lumiere/exposition/resolution/SPP, sans denoise ;
seed fixe si possible, sinon seuil calibre sur captures repetees du temoin.
Toutes validations headless locales : --gpu=false, --mode="Pathtracer MTLX",
--denoise=false pour les controles de transport/shading. Les controles dedies au
denoiser activent explicitement le denoiser navigateur et conservent aussi l'image brute.
GPU reel via Android/Adreno. npm run build apres changements executables.
npm test actuel n'est pas utilisable : ajouter des commandes dediees aux jalons 1/2.

## Etapes et controles bloquants

### 0. Figer contrats et provenance [REQ-001 a REQ-008]
- [x] Jalon 0 termine le 2026-10-04 sur decision explicite de l'utilisateur.
- [x] T001 [Plan:0] Relever revisions/licences ; inspecter mesh.ts#buildBVH, upload pathtracerRenderer.ts et corpus .scene. [Source: D:/WebGL2/GLSL-PathTracer-JS/src/core/mesh.ts] [Evidence: research-t001.md ; validate-t001.mjs]
- [x] T002 [Plan:0] Figer contrats hit/textures/instances/camera/lumieres et table des directives sous specs/005-mtlx-reference-alignment/. [Evidence: contracts-t002.md ; scene-directives.json ; validate-t002.mjs]
Contrats techniques v1 figes ; T002 termine au perimetre documentaire.
Cloture du jalon sur demande de l'utilisateur ; les reserves de provenance encore
ouvertes deviennent un suivi non bloquant pour T003, pas des preuves de droits acquises.
Conserver les notices applicables et documenter les droits avant redistribution.
Poids HDR/LDR identifies dans D:/WebGL2/Denoiser/packages/denoiser/tzas : provenance,
version, hashes et licence verifiees dans contracts-t002.md, sans deploiement runtime.
Controle manuel : source -> destination -> ecart -> test, choix Bvh/SplitBvh et
parametres effectifs, matrices/FOV, materiaux non-MTLX et priorite des lumieres.
Passage : aucune convention decisive ouverte ; mode distant confirme NON-MTLX.
Pour le denoiser, inventorier bundle/poids/dependances, contrat couleur/HDR/alpha,
orientation, nombre de canaux, backend et disponibilite hors reseau. Definir un budget
de temps/memoire et la politique en cas d'echec : image brute avec diagnostic, jamais OIDN.

### 1. Capturer les temoins [REQ-001, REQ-007, REQ-008]
- [x] T003 [Plan:1] Preparer corpus/runner dans tools/mtlx-reference-alignment/ avec launch_render.mjs, sharp et playwright-core. [Evidence: tools/mtlx-reference-alignment/README.md ; run.test.mjs ; artifacts/mtlx-reference-alignment/t003-smoke/]
Corpus actualise : 19 cas (16 locaux, 3 reference non-MTLX), 9 tests du runner passes.
- [x] T004 [Plan:1] Capturer baseline locale et fixtures distantes NON-MTLX dans artifacts/mtlx-reference-alignment/01-baseline/. [Evidence: t004-baseline.md ; baseline-manifest.json ; validate-baseline.mjs]
- [x] Jalon 1 valide le 2026-10-05 pour les captures, avec volet HDR/denoiser reporte aux etapes 14-15 par l'utilisateur.
19 captures 256x256/128 SPP reussies ; temoins or/bleu, normal-map complet et
reference non-MTLX controles. Faux 404 Windows corrige par normalisation de root,
budget maxspp reference ajuste via scene temporaire. Images, hashes, uniforms,
GLSL et logs conserves. Disney Gold repete : pixels RGB identiques.
Revue et limites dans t004-baseline.md ; T005 non commencee.
Controle : build ; standard-shader-ball, glavenus, terrain, bearded-man, disney-gold,
cinq familles MTLX, normal-map/anisotropie/transmission/volume/thin-film disponibles.
32 SPP smoke, 128 SPP comparaison ou davantage si bruit. Figer budgets temps/memoire.
Passage : baseline reproductible, anomalies preexistantes notees, mode reel verifie.
Decision utilisateur du 2026-10-05 : reporter aux etapes 14-15 les entrees HDR
a faible SPP et les sorties du denoiser distant sur ces memes buffers. Ce volet
ne bloque plus T004 ; il reste obligatoire pour la validation du denoiser, pas
pour le shading MTLX distant (toujours exclu).

### 2. Importer TS sans basculer [REQ-001, REQ-002, REQ-007]
- [x] T005 [Plan:2] Reprendre TS/math dans src/bvh/reference/ sans modification algorithmique. [Source: D:/WebGL2/GLSL-PathTracer-JS/src/bvh/] [Evidence: src/bvh/reference/SOURCES.json ; README.md ; tools/mtlx-reference-alignment/reference-import.test.mjs]
Reprise : BBox/Bvh/SplitBvh/BvhTranslator et Vec3/Vec4, 6 sources SHA-256 figees.
Seule adaptation upstream : import Mesh/MeshInstance type-only ; declarations locales
minimales, sans moteur distant. Notices MIT AMD et Asif conservees. 4 tests PASS,
build PASS pour T005 ; aucune activation reference. T006 ajoute ensuite la selection
explicite, Three.js reste actif et le GLSL reste inchange.
- [x] T006 [Plan:2] Ajouter runner TS et backend explicite dans main.js, Three.js restant actif. [Evidence: t006-runner-backend.md ; backend.test.mjs ; reference-runtime.test.ts]
- [x] Jalon 2 valide le 2026-10-05 : 19 tests npm passent, build PASS, smoke local identique a T004 et refus reference sans fallback.
tsx 4.20.6 verrouille ; bvh_backend default=threejs, reference NOT_READY.
GPU/dispatch/GLSL reference non integres ; T007 ajoute seulement l'adaptateur CPU isole.
Controle : imports Node/Vite, build, smoke local inchange ; aucune dependance a Main,
DOM, renderer ou generateur MTLX distant dans les modules algorithmiques.

### 3. Construire les BLAS [REQ-002, REQ-007]
- [x] T007 [Plan:3] Adapter geometries indexees/non indexees, primitives/groupes/attributs dans src/bvh/referenceSceneAdapter.js. [Source: D:/WebGL2/GLSL-PathTracer-JS/src/core/mesh.ts] [Evidence: t007-geometry-adapter.md ; reference-scene-adapter.test.ts]
T007 : 26 tests dont 7 d'adaptateur, build PASS ; positions objet/attributs/groupes
preserves, sans build BLAS a cette etape.
- [x] T008 [Plan:3] Reprendre Bvh/SplitBvh et parametres ; tester structure dans tools/mtlx-reference-alignment/. [Evidence: t008-blas.md ; referenceBlas.js ; reference-blas.test.ts]
- [x] Jalon 3 valide le 2026-10-05 : 35 tests npm passent, dont 9 controles T008, build PASS.
BLAS CPU SplitBvh avec parametres exacts ; feuilles/couverture/bounds/permutations
verifiees, comparaisons aux modules TS upstream isoles conformes. Backend reference
toujours non active ; T009 ajoute ensuite le TLAS CPU, sans integration GPU.
Controle auto : triangle/cube/coplanaires/centroides identiques/degeneres/vide,
bounds/permutation/couverture/doublons spatial splits/feuilles multi-triangles.
Passage : conforme aux modules TS isoles, pas de triangle perdu ni boucle infinie.

### 4. Construire TLAS et traduire [REQ-002, REQ-004, REQ-007]
- [x] T009 [Plan:4] Reprendre createTLAS/processBLAS/processTLAS/topLevelIndex/updateTLAS dans l'adaptateur. [Source: D:/WebGL2/GLSL-PathTracer-JS/src/core/pathtracer/pathtracerScene.ts] [Source: D:/WebGL2/GLSL-PathTracer-JS/src/bvh/bvhTranslator.ts] [Evidence: t009-tlas.md ; referenceScene.js ; reference-scene.test.ts]
43 tests npm passent, dont 8 T009 ; build PASS. Bounds monde et traduction CPU,
BLAS partage, matrices et offsets verifies ; prefixe BLAS preserve lors d'update.
Backend non active. T010 approfondit ensuite les cycles et la stabilite des traductions.
- [x] T010 [Plan:4] Tester BLAS partage, IDs distincts et reconstructions repetees. [Evidence: t010-instance-cycles.md ; reference-scene.test.ts]
- [x] Jalon 4 CPU valide le 2026-10-05 : 49 tests npm passent, build PASS.
64 updates, 40 transitions et 32 cycles A-B-A conformes aux constructions neuves ;
defaut de reutilisation process upstream reproduit et evite par la frontiere locale.
BLAS et attributs inchanges, pas de backend GPU active. T011 ajoute l'upload isole.
Controle : rotation/translation/echelle non uniforme ou negative/hierarchie glTF,
LRLeaf interne=0/BLAS>0/TLAS=-instanceIndex-1, offsets globaux, bounds monde et IDs.
Passage : pas de double transform, racines accumulees ou BLAS inutilement reconstruit ;
matrices singulieres en erreur explicite. Documenter corrections necessaires du port.

### 5. Uploader et relire les textures [REQ-002, REQ-003, REQ-007]
- [x] T011 [Plan:5] Implementer src/bvh/referenceGpuAdapter.js : BVH/indices/vertices/normals/transforms/topBVHIndex. [Source: D:/WebGL2/GLSL-PathTracer-JS/src/core/pathtracer/pathtracerRenderer.ts] [Evidence: t011-gpu-textures.md ; reference-gpu-adapter.test.ts ; t011-upload-smoke.json]
55 tests npm et build PASS ; upload isole Chrome/SwiftShader sans erreur GL.
RGBA physique avec ABI logique RGB conservee, decision utilisateur explicite.
Backend reference non active ; T012 ajoute la relecture texelFetch.
- [x] T012 [Plan:5] Ajouter probe GPU de packing dans tools/mtlx-reference-alignment/. [Evidence: t012-gpu-readback.md ; gpu-readback-probe.mjs ; t012-gpu-readback.json]
152 texels des cinq samplers relus bit a bit via WebGL2/SwiftShader ; tests et build PASS.
Controle debut/fin/lignes, sampler entier, padding, Nearest, orientation/couleur,
formats/matrices, capacites texture/samplers et precision float32 passe. Jalon 5 valide.

### 6. Porter closest-hit [REQ-001, REQ-003, REQ-007]
- [x] T013 [Plan:6] Reprendre intersection/closest_hit GLSL dans glsl/pathtracing/mtlx/reference/ et glsl-sources.js. [Source: D:/WebGL2/GLSL-PathTracer-JS/shaders/common/closest_hit.glsl] [Evidence: t013-closest-hit-glsl.md ; closest_hit.glsl ; closest-hit-compile-smoke.mjs]
Source byte-identique au hash T001 ; import ?raw expose, compilation/link ESSL 3.00 isoles PASS.
Pas de raccord a trace() ni d’activation runtime ; T014 porte integration et oracle rayon.
- [x] T014 [Plan:6] Relier uniquement le hit geometrique a trace() dans glsl/pathtracing/mtlx/pathtracer.glsl ; garder sol/shading. [Evidence: t014-closest-hit-trace.md ; reference-ray-oracle.mjs ; t014-reference-ray-oracle.json ; t014-default-branch-smoke.json]
Branche sous REFERENCE_BVH_ENABLED, non definie au runtime ; maxDistance, sorties
geometrie et garde pile 64 verifies, sans changer sol ou shading local.
Oracle CPU/GPU : 10 000 rayons, 6 946 hits/3 054 misses, zero divergence ; T015 porte any-hit.

### 7. Porter any-hit et les ombres [REQ-001, REQ-003, REQ-007]
- [x] T015 [Plan:7] Reprendre any-hit avec maxDistance vers TraceShadow local. [Source: D:/WebGL2/GLSL-PathTracer-JS/shaders/common/anyhit.glsl] [Evidence: t015-any-hit-shadow.md ; anyhit_mtlx.glsl ; t015-shadow-oracle.json ; t015-default-branch-smoke.json]
AnyHit géométrique et TraceShadow sous macro dormante ; maxDistance/sol preserves,
oracle 10 000 rayons sans divergence.
- [x] T016 [Plan:7] Garder filtres locaux opacite/thinwalled, sans alpha-test materialsTex/atlas distant. [Evidence: t016-local-shadow-filters.md ; shadow-filter.test.mjs ; t015-shadow-oracle.json ; t016-default-branch-smoke.json]
Six politiques locales passent ; AnyHit sans alpha/atlas distant ; sol, opaque,
thin-walled et segments bornes verifies. Le mapping des IDs reference est T017.

### 8. Verrouiller shading et materialID [REQ-001, REQ-004, REQ-007]
- [x] T017 [Plan:8] Relier IDs TLAS au registre local dans main.js sans reduction a un flag. [Evidence: t017-materialid-registry.md ; referenceMaterialRegistry.js ; t017-material-registration-smoke.json]
Registry sparse sceneID/kind/localID/parameterVariant ; coverage fail-closed et
parametres de closure verifies. IDs distincts gardes, variantes partageant la meme closure.
- [ ] T018 [Plan:8] Verifier prepare/evaluate/sample/opacite/thinwalled/emission/milieu du materiau touche dans le GLSL local.
Controle : corpus A/B LOCAL, instances a materiaux distincts, normal-map/UV/anisotropie,
volume/transmission/film ; dispatch local stable pour entrees identiques.
Si closures heterogenes depassent le registre actuel, sous-jalon bloqueur dedie.
T018 verifie l’application des variants dans tous les hooks et la fidelite des materiaux.

### 9. Parser .scene sans renderer [REQ-004, REQ-005, REQ-006, REQ-007]
- [ ] T019 [Plan:9] Adapter syntaxe dans src/scene/sceneLoader.js, parsing pur separe du chargement. [Source: D:/WebGL2/GLSL-PathTracer-JS/src/core/pathtracer/loaders/sceneLoader.ts]
- [ ] T020 [Plan:9] Parser material/light/camera/renderer/mesh/gltf, MTLX inline/document, object/glob ; diagnostics ligne/nom/directive.
Controle auto : BOM/CRLF/commentaires/espaces/guillemets/matrix-TRS, valeurs non finies,
bloc ouvert, refs inconnues et MTLX ambigu. Parsing distant avec doubles de services
seulement, jamais generateur distant. Passage : chaque directive supportee/adaptee/rejetee.

### 10. Charger les ressources localement [REQ-001, REQ-002, REQ-004, REQ-007]
- [ ] T021 [Plan:10] Ajouter src/scene/referenceSceneAdapter.js et scene_url dans main.js, conserver scenes nommees.
- [ ] T022 [Plan:10] Relier loaders geometrie utiles, generation MTLX LOCALE et envmap locale ; URLs relatives par ressource.
Controle navigateur : sous-dossier .scene/.mtlx/textures, glTF/GLB, overrides objets,
meshes repetes et formats mesh requis supportes/rejetes explicitement ; 404/erreur
generation/reloads concurrents. Passage : chargement atomique, bons IDs/comptes,
pas de scene/programme stale. Ajouter scene_url au runner apres verification CLI/URL.

### 11. Camera et profondeur de champ [REQ-005, REQ-007]
- [ ] T023 [Plan:11] Implementer src/scene/cameraAdapter.js : position/lookat/matrix/FOV, priorite scene puis overrides explicites. [Source: D:/WebGL2/GLSL-PathTracer-JS/src/core/camera.ts]
- [ ] T024 [Plan:11] Adapter reset_camera/sync_shader_uniforms et seulement les rayons primaires locaux pour aperture/focalDist.
Controle CPU/GPU et distant NON-MTLX : base/forward/FOV horizontal-vertical/degres-radians,
column-row-major, rayons centre/coins, aspects 1:1/16:9/9:16, aperture=0 puis plan focal.
Documenter roll de matrix -> lookat. Passage : cadrage/DOF corrects, camera non ecrasee,
orbit/resize/reload remettent l'accumulation a zero.

### 12. Lumieres et emetteurs [REQ-001, REQ-006, REQ-007]
- [ ] T025 [Plan:12] Implementer src/scene/lightAdapter.js, enums/buffers reference et extensions point/spot locales. [Source: D:/WebGL2/GLSL-PathTracer-JS/src/core/light.ts]
- [ ] T026 [Plan:12] Adapter GetMtlxLight/LiDirect/LiPDF et hits d'emetteurs dans le GLSL local, sans remplacer l'integrateur.
Quatre sous-jalons, controle obligatoire apres chacun :
1. Parsing/packing : v1/v2 -> u/v, aire quad/sphere, rayon, distant, emission lineaire,
   enums/comptes/relecture GPU ; zero lumiere inclus.
2. NEE : une lumiere, skyPower=0, soleil/envmap desactives, materiau non emissif ;
   distance/orientation/ombre/proportionnalite emission et fixture distante NON-MTLX.
3. Emetteurs visibles : quad/sphere aux rayons primaires/speculaires, distance vs
   geometrie, backfaces et hideemitters ; controle geometrique et visuel non-MTLX.
4. MIS : selection de lumiere, PDF aire -> angle solide, pas de PDF delta pour quad/sphere.
   NEE seule/BSDF seule/MIS sur fixture diffuse locale convergee et reference analytique,
   marge statistique calibree, aucune luminosite doublee.
Definir sens distant depuis sampling. Lumieres .scene autoritaires, fusion MTLX/overrides
uniquement explicite. Passage : quatre controles passes, puis plusieurs lumieres + envmap.

### 13. Options et cycle de vie [REQ-001, REQ-004, REQ-005, REQ-006, REQ-007]
- [ ] T027 [Plan:13] Mapper renderer resolution/maxdepth/maxspp/volume/clamp/envmap/affichage dans main.js ; autres options rejetees/documentees.
- [ ] T028 [Plan:13] Verifier ressources/invalidation shaders/accumulation aux transitions.
Controle : A -> B -> A, scene/materiau/camera/lumiere/instance, resize, R raster ->
pathtracer, erreur puis reprise. Uniforms avant warm-up, samplers cube/2D distincts.
Mode incompatible .scene en refus explicite. Passage : pas d'etat perime, fuite
croissante ou accumulation melangee ; readiness fiable.

### 14. Reprendre et brancher le denoiser navigateur [REQ-001, REQ-007, REQ-008]
Inclut le volet de baseline HDR/denoiser reporte de T004 sur decision utilisateur
du 2026-10-05 : sauvegarder les memes buffers bruts a faible SPP et la reference
locale a fort SPP avant d'evaluer les sorties du denoiser distant hors pipeline MTLX.
- [ ] T029 [Plan:14] Reprendre bundle/poids/notices dans src/denoiser/reference/ et public/denoiser/ ; creer src/denoiser/referenceDenoiserAdapter.js. [Source: D:/WebGL2/GLSL-PathTracer-JS/src/external/denoiser/denoiser.js]
- [ ] T030 [Plan:14] Relier image accumulee, controle GUI et sortie de presentation dans main.js, sans modifier le buffer d'accumulation. [Source: D:/WebGL2/GLSL-PathTracer-JS/src/core/pathtracer/pathtracerRenderer.ts]
Deux sous-jalons avec controle obligatoire entre eux :
1. Initialisation : import Vite/dev/build, modele et poids locaux, readiness et execution
   sur petit buffer Float32Array connu ; zero requete CDN obligatoire, aucun OIDN lance.
2. Branchement : lecture du render target a la resolution de rendu, canaux/stride/alpha,
   flip Y et espace couleur/HDR verifies ; comparer a l'API distante sur le meme buffer.
   Tester valeurs >1, noir, NaN/Inf et pattern asymetrique ; conversion d'entree explicite,
   sans ecretage HDR silencieux ni double tonemapping/exposition.
Controle : raw/denoised selectionnables, resultat fini et dimensions exactes ; le denoiser
ne reinjecte jamais sa sortie dans l'accumulation et ne modifie pas les BSDF locaux.
Verrouiller les executions ; abort/invalidation par revision scene/camera/SPP/resize,
ignorer callbacks perimes, restaurer etat GL Three.js et liberer tensors/textures/listeners.
Passage : image brute inchangee avec denoiser off et aucun resultat d'une ancienne scene affiche.

### 15. Valider le denoiser et remplacer OIDN dans les captures [REQ-001, REQ-007, REQ-008]
- [ ] T031 [Plan:15] Ajouter tests qualite/cycle de vie du denoiser dans tools/mtlx-reference-alignment/, fixtures et budgets dans artifacts/mtlx-reference-alignment/.
- [ ] T032 [Plan:15] Adapter launch_render.mjs pour --denoise=true via le navigateur : attendre le resultat du SPP cible, capturer puis retirer oidnDenoise.exe, --oidn et conversions PFM. Mettre a jour README.md.
Deux sous-jalons avec controle obligatoire entre eux :
1. Qualite : images locales a faible SPP vs reference locale fort SPP, metriques
   RMSE/PSNR et inspection des textures fines, bords, normal-maps, reflets, emission,
   transmission et thin-film. Calibrer seuils par fixture, pas d'amelioration supposee
   pour tous les materiaux ; absence de flou excessif, biais couleur et hautes lumieres coupees.
2. Captures : attendre readiness puis fin du denoise de la revision et du SPP demandes,
   pause/snapshot coherent, timeout/erreur explicite pour la CLI ; exporter brut et denoise.
   --denoise=false garde son comportement ; --denoise=true ne lance aucun executable externe.
Controle : runs repetes, toggle, resize, A -> B -> A, annulation et ressource modele
manquante ; verifier budgets temps/memoire, absence de fuite tensor/GL et de runs concurrents.
Passage : qualite et captures validees avant retrait OIDN, aucune dependance a son
installation ou a D:/oidn-2.5.0 ; --oidn obsolete rejete clairement, pas ignore silencieusement.

### 16. Recette et mobile [REQ-001 a REQ-008]
- [ ] T033 [Plan:16] Executer corpus donnees/rayons/probes/images local, denoiser on/off et mesures bearded-man/instances.
- [ ] T034 [Plan:16] Recette Android/Adreno via ADB : compilation, 64 SPP, quad/transmission, denoiser on/off, transitions et resize.
Controle : corpus passe, aucune erreur console/GLSL/WebGL/context loss, image non vide,
budgets jalon 1 respectes ou ecarts acceptes. Device absent = jalon non valide,
pas assimile a SwiftShader. Passage : preuves auto/manuelles et ecarts source/local acceptes.

### 17. Basculer et nettoyer [REQ-001, REQ-002, REQ-003, REQ-007, REQ-008]
- [ ] T035 [Plan:17] Reference par defaut pour Pathtracer MTLX dans main.js ; retirer switch apres recette.
- [ ] T036 [Plan:17] Nettoyer seulement adaptations BVH et appels denoiser externe devenus inutiles, documenter provenance/ecarts dans README.md.
Controle : build/smoke anciennes scenes et .scene ; GLSL compile sans reecriture
MeshBVH pour Pathtracer MTLX ; raster/legacy sans regression. Garder three-mesh-bvh
et bvh-compat.js tant qu'une autre route en depend. Passage : backend actif verifie,
docs a jour, retour au jalon precedent sans annuler le travail utilisateur.
Verifier absence d'appel executable OIDN dans viewer/captures et smoke --denoise=true/false.

## Commandes et couverture

Exemple de capture locale, commandes existantes :
```powershell
npm run build
node launch_render.mjs --mode="Pathtracer MTLX" --gpu=false --denoise=false --scene=standard-shader-ball --spp=32 --size=256x256 --output=artifacts/mtlx-reference-alignment/01-baseline/standard-shader-ball.png
```
Commandes des nouveaux tests a ajouter aux etapes 1/2. Aucun test de migration execute
pendant cette planification. Eviter --mode=mtlx sans verification du mode reel.
Pour le distant, confirmer son mode NON-MTLX et l'absence de generation MTLX dans les logs.

| Exigence | Etapes | Preuves |
| --- | --- | --- |
| REQ-001 | 0,1,2,6,7,8,10,12,13,14,15,16,17 | GLSL/dispatch locaux preserves, A/B local, aucune generation MTLX distante. |
| REQ-002 | 0,2,3,4,5,10,17 | TS, BLAS/TLAS, buffers/tests structurels. |
| REQ-003 | 0,5,6,7,17 | GLSL repris, probes/oracle de rayons. |
| REQ-004 | 0,4,8,9,10,13 | Loader/ressources/instances/IDs. |
| REQ-005 | 0,9,11,13 | Camera/uniforms/rayons/DOF. |
| REQ-006 | 0,9,12,13 | Lumieres/packing/NEE/emetteurs/MIS. |
| REQ-007 | 0 a 17 | Controle bloqueur documente par jalon et sous-jalon. |
| REQ-008 | 0,1,14,15,16,17 | Denoiser distant repris, buffers/couleur valides, qualite et captures sans executable externe. |

Ordre obligatoire : 0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8 -> 9 -> 10 -> 11 -> 12 -> 13 -> 14 -> 15 -> 16 -> 17.