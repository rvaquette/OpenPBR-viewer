# Taches: migration WebGPU

**Input**: [plan.md](./plan.md)

**Portee**: Migration incrementale du `Pathtracer MTLX` vers WebGPU/WGSL, tout en conservant WebGL2 comme reference visuelle et repli explicite. Le rasterizer WebGPU est une phase finale, bloquee par la parite du path tracer.

**Validation**: `npm run build`, validation navigateur WebGPU, captures Playwright via `launch_render.mjs`, contrats de generation MaterialX et comparaisons de baseline.

**Regle d'implementation**: Le backend WebGPU ne traduit jamais le GLSL genere par MaterialX via des regex JavaScript. `MtlxPathTracerHostWgslShaderGenerator` continue de produire du GLSL Vulkan valide; un pipeline outille (`glslang` puis `naga`/`Tint`) le compile en SPIR-V puis le transpile en WGSL avant toute consommation par l'integrateur WebGPU.

## Phase 1: Baseline et contrats communs

**Purpose**: Figer le comportement WebGL de reference et isoler les donnees partagees entre backends avant tout rendu WebGPU.

- [X] T001 Ajouter `renderer_backend` (`webgl` par defaut, `webgpu` explicite) aux parametres URL et au diagnostic runtime dans `main.js`.
- [X] T002 [P] Definir une matrice de support navigateur/GPU WebGPU et le comportement de repli explicite WebGL2 dans `specs/005-webgpu-migration/`.
- [X] T003 [P] Ajouter un manifeste de baseline versionne avec scene, materiau, URL, resolution, samples, bounces, seed, version du bundle MTLX et hash d'image dans `artifacts/webgpu-migration/`.
- [X] T004 Etendre `launch_render.mjs` ou creer un runner dedie pour capturer les baselines WebGL des scenes `standard-shader-ball`, `glavenus`, `terrain` et `bearded-man` en `Pathtracer MTLX`.
- [X] T005 Capturer les baselines WebGL pour les materiaux opaques, metal, verre, texture procedurale et emissif; renseigner leurs hashes dans le manifeste.
- [X] T006 [P] Definir les metriques de comparaison WebGL/WebGPU: erreur RGB moyenne, taux de pixels hors seuil, statistiques de luminance et exceptions de precision connues.
- [X] T007 Extraire de `main.js` un contrat de scene independant du renderer couvrant camera, dimensions, parametres de rendu, lumières, textures, geometrie et etat d'accumulation.

**Checkpoint**: Les captures de reference sont reproductibles et la structure de donnees du viewer peut alimenter un second backend sans modifier le comportement WebGL.

---

## Phase 2: Hote WebGPU et smoke test

**Purpose**: Initialiser WebGPU de maniere fiable et rendre un premier pipeline WGSL sans toucher au path tracing.

**Depends on**: T001, T007

- [X] T008 Creer `src/webgpu/WebGpuRenderer.js` avec creation adaptateur/device, negotiation de format canvas et gestion de `device.lost`.
- [X] T009 [P] Creer les modules de support WebGPU: validation des limites de l'adaptateur, gestion des erreurs scopes et destruction idempotente des ressources dans `src/webgpu/`.
- [X] T010 Creer un shader WGSL de smoke test et son pipeline compute/presentation: couleur stable, compteur de frame et couverture complete du canvas.
- [X] T011 Integrer `WebGpuRenderer` a l'initialisation du viewer sans modifier le chemin `WebGLRenderer` existant.
- [X] T012 Relier WebGPU aux evenements `load_scene`, `resize`, `resetSamples`, pause/reprise et boucle `render`.
- [X] T013 Ajouter une erreur utilisateur explicite pour WebGPU indisponible, adaptateur refuse, erreur WGSL ou perte de device; ne pas basculer silencieusement de `webgpu` a `webgl`.
- [X] T014 Ajouter une smoke validation navigateur de `?renderer_backend=webgpu`, incluant resize et perte/recreation controlee du renderer si le navigateur le permet.
- [X] T015 Verifier par test de non-regression que `?renderer_backend=webgl` conserve les quatre modes actuels.

**Checkpoint**: Le backend WebGPU initialise et presente un frame de test; WebGL reste fonctionnel sans divergence comportementale.

---

## Phase 3: Layouts GPU, geometrie, BVH et accumulation

**Purpose**: Remplacer les textures de donnees GLSL par des buffers WebGPU et etablir le cycle d'accumulation compute.

**Depends on**: T008-T012

- [X] T016 Definir les layouts binaires JS/WGSL de `CameraUniforms`, `RenderUniforms`, `Light`, `BvhNode`, `TriangleIndices` et attributs sommets dans `src/webgpu/`; documenter alignements, tailles et offsets.
- [X] T017 Ajouter des tests unitaires de layout qui verifient les tailles, alignements de 16 octets et offsets entre les writers JavaScript et les declarations WGSL.
- [X] T018 Convertir la sortie de `buildCombinedSurfaceGeometry()` en buffers de stockage WebGPU: positions, indices, normales, tangentes, UV et `neutralFlag`.
- [X] T019 Porter le format du BVH natif de `src/bvh/` en upload GPU; eviter de reconstruire le BVH dans le shader.
- [X] T020 Porter `nativeBvhIntersectFirstHitWithinDistance` vers WGSL et ajouter une telemetrie de debordement de stack ou d'acces invalide.
- [X] T021 Ajouter un mode diagnostic WGSL pour distance de hit, identifiant de materiau, normales et UV afin de valider geometrique et interpolation.
- [X] T022 Creer les textures d'accumulation ping-pong et le reset GPU, avec un format HDR negocie/valide contre les fonctionnalites de l'adaptateur.
- [X] T023 Creer le passage de presentation WGSL: moyenne par sample, conversion lineaire et tonemapping vers le format du canvas.
- [X] T024 Integrer l'accumulation WebGPU aux compteurs `samples` et `max_samples`, aux controles pause et aux changements de camera/parametres.
- [X] T025 Executer les diagnostics sur scene neutre puis `standard-shader-ball`; verifier hit, normale, UV, sol, resize, reset et reprise d'accumulation.

**Checkpoint**: Le backend WebGPU traverse la scene et accumule une image HDR stable, avant toute dependance MaterialX.

---

## Phase 4: Integrateur WGSL sans MaterialX

**Purpose**: Porter l'integrateur et les ressources de scene tout en gardant des BRDF de reference simples et inspectables.

**Depends on**: T020-T024

- [X] T026 Porter de `glsl/pathtracing/mtlx/common.glsl` vers `src/webgpu/shaders/`: RNG, `Basis`, transformations local/monde, Fresnel, GGX, echantillonnage hemispherique et MIS.
- [X] T027 Porter `trace`, ombres, dispatch des materiaux props/sol et les BRDF Lambert depuis `glsl/pathtracing/mtlx/pathtracer.glsl`.
- [X] T028 Porter le sol texture et ses conventions UV existantes; verifier l'espace couleur des textures WebGPU.
- [X] T029 Porter soleil analytique, lumières MTLX point/directionnelle/spot/quad et leur echantillonnage/MIS.
- [X] T030 Porter l'envmap avec echantillonnage cosinus actuellement valide; laisser la branche CDF surexposee desactivee jusqu'a correction documentee.
- [X] T031 Ajouter des modes diagnostics URL pour PDF, nombre de rebonds et contribution de chaque famille de lumiere.
- [X] T032 Valider independamment Lambert, reflection speculaire, metal, sol texture, lumières et envmap avec les diagnostics et les seuils de T006. Lambert, sol texture et envmap valides (`tools/verify-webgpu-reference-materials.mjs`); reflexion speculaire/metal restent hors-perimetre (BRDF MaterialX, voir T032.1); les 4 familles de lumieres sont validees par T032.2 et ses sous-taches.
- [X] T032.1 Specular/metal reference BRDFs restent non testables avant MaterialX (Phase 5/6); consigne deja dans `artifacts/webgpu-migration/phase4-validation.json` sous `notYetComparableFamilies`. Aucune action supplementaire attendue avant la generation MaterialX.
- [X] T032.2 Corriger le bug decouvert: la boucle `lights[]` dans `evaluateDirectLight()` (`src/webgpu/WebGpuRenderer.js`) n'a aucun effet visible sur la sortie, meme avec une intensite jusqu'a 1000 et `frame.lightCount`/`mtlxRouteLights` confirmes corrects cote JavaScript; le terme sun/sky de la meme fonction fonctionne. Les sous-taches T032.2.1-T032.2.8 sont valides; le gate de rendu reel passe pour point, directionnelle, spot et quad, avec `knownIssues=[]` dans `artifacts/webgpu-migration/phase4-validation.json`.
- [X] T032.2.1 Figer le repro et les controles: etendre `tools/test-lights-array-minimal.mjs` et `public/minimal-lights-test.html` pour produire un resultat structure contenant le layout attendu (24 floats, offsets des six `vec4`, valeur `lightCount` et valeur calculee), puis ajouter un cas de controle `lightCount=0` et un cas `lightCount=1`; conserver les captures/valeurs dans la sortie du test. Validation: le cas minimal passe avec `actual=expected` et le cas sans lumière reste nul.
- [X] T032.2.2 Instrumenter le contrat d'entree du viewer: ajouter un hook de diagnostic non destructif expose par `main.js` et/ou `WebGpuRenderer` qui retourne le nombre de lumières, le type, la position, l'intensite, le stride et la taille du buffer effectivement prepares; verifier que `mtlx_lights_json` produit la meme donnee que `setLights()`. Validation: un test navigateur confirme `lightCount=1`, `stride=96` octets et les champs de la lumière point attendue avant le dispatch.
- [X] T032.2.3 Isoler l'upload et la lecture GPU dans le renderer: créer un chemin de diagnostic compute/readback ou un shader debug qui lit `lights[0]` et écrit ses champs dans une sortie observable, sans passer par BVH, matériau, envmap ou BRDF; vérifier la copie `queue.writeBuffer`, l'usage `COPY_DST`, la durée de vie du buffer et la recreation des bind groups après `setLights()`. Validation: les valeurs lues par WGSL sont identiques aux valeurs JS dans le navigateur réel.
- [X] T032.2.4 Isoler `frame.lightCount` et la boucle: ajouter temporairement un mode diagnostic qui écrit une couleur constante lorsque `frame.lightCount > 0u`, puis une seconde couleur issue de `lights[0]`; vérifier aussi le compteur dans le buffer uniforme et le nombre d’itérations de la boucle. Retirer ou conserver uniquement le hook de diagnostic documente apres le triage. Validation: `lightCount=0` et `lightCount=1` produisent deux sorties distinctes dans le viewer.
- [X] T032.2.5 Corriger la cause racine identifiee dans un seul contrat: appliquer la correction minimale au writer JS, au layout WGSL, au bind group ou au cycle de rendu selon les résultats du diagnostic; ne pas compenser par une constante, un lobe parallèle ou une modification des seuils d'image. Ajouter un test de non-regression ciblé sur le cas qui échouait. Le faux negatif venait du test: la baseline etait capturee avec la lumière deja active et `toDataURL()` ne capturait pas correctement le canvas WebGPU; le test compare maintenant `setLights([])` puis `setLights([light])` via screenshot Playwright.
- [X] T032.2.6 Valider la contribution physique d'un point et d'une directionnelle en environnement isolé: désactiver l'envmap/sky pour la capture, utiliser une scène Lambert déterministe et comparer une image sans lumière à une image avec lumière d'intensite connue; vérifier que la différence est localisée et non nulle, et que le résultat varie avec la position/direction. Validation réalisée par `tools/test-lights-loop.mjs` avec `skyPower=0` et `sunPower=-4`: point delta luminance `1.392`, directionnelle delta RGB non nul.
- [X] T032.2.7 Étendre la validation aux spot et quad et vérifier le packing complet: tester les quatre types via `mtlx_lights_json`, les cones `innerCone/outerCone`, `edgeU/edgeV`, la sélection uniforme et l'attenuation; vérifier qu'aucun type ne dépend accidentellement du contenu résiduel d'un autre buffer ou de l'envmap. Validation: `tools/test-lights-loop.mjs` passe avec point, directional, spot et quad; le readback quad confirme `edgeU=[10,0,0,0]` et `edgeV=[0,0,10,0]`, avec sky/soleil neutralisés.
- [X] T032.2.8 Fermer le gate de rendu réel: exécuter `node tools/verify-webgpu-reference-materials.mjs` sur le viewer complet, enregistrer les captures et les mesures dans `artifacts/webgpu-migration/phase4-validation.json`, supprimer le statut `known-issue` pour les quatre familles uniquement si toutes passent, puis lancer `npm run build`. Validation: les quatre familles passent avec `meanLuminanceDeltaVsBaseline` non nul, `knownIssues=[]` et `npm run build` réussi.
- [X] T033 Comparer les captures WebGPU sans MaterialX au baseline WebGL applicable; enregistrer les ecarts acceptes dans le manifeste (`phase4-validation.json.webglComparison`, divergence de couleur materiau Lambert vs `open_pbr_default` documentee comme acceptee).

**Checkpoint**: Le path tracer WGSL converge sur des scenes sans dispatch MaterialX et passe les invariants de trace/eclairage.

---

## Phase 5: Generation MaterialX GLSL, transpilation SPIR-V vers WGSL et publication WASM

**Purpose**: Porter la generation MaterialX vers un GLSL Vulkan valide, transpiler ce GLSL en WGSL via SPIR-V, publier le runtime WASM compatible puis le brancher au viewer WebGPU.

**Depends on**: T026-T033

**Repository externe**: `../MaterialX-rva`

- [X] T034 Inventorier l'API et les dependances de `JsWgslShaderGenerator.cpp`, `MtlxPathTracerHostShaderGenerator` et du build Emscripten actuel dans `../MaterialX-rva`.
- [X] T035 Integrer `JsWgslShaderGenerator.cpp` a la cible Emscripten et exporter sa fabrique, les contextes et types MaterialX requis sans retirer `PathTracerGlslShaderGenerator`.
- [X] T036 Porter `MtlxPathTracerHostShaderGenerator` en `MtlxPathTracerHostWgslShaderGenerator` base sur `WgslShaderGenerator`; ce generateur reste un producteur de GLSL Vulkan, destine a la transpilation, sans dependance vers `PathTracerGlslShaderGenerator`.
- [X] T036.1 Garantir que `MtlxPathTracerHostWgslShaderGenerator` emet un GLSL Vulkan strict et compilable par `glslang`: `#version 450`, `layout(set=N, binding=M)` explicites pour chaque ressource, sans qualifiers ou extensions incompatibles avec la cible SPIR-V retenue. Le host utilise désormais `VkShaderGenerator`, les ressources Vulkan émettent `set=0`/`binding=N`, les extensions incompatibles sont rejetées et le build Release `MaterialXGenGlsl` passe; `glslangValidator` n'est pas disponible dans l'environnement de validation courant.
- [X] T036.2 Choisir et integrer `glslang` (GLSL -> SPIR-V) dans `tools/`: version figee, flags de cible (`--target-env vulkan1.x`), invocation reproductible en CI et en local. La configuration est `tools/glslang-config.json` (glslangValidator 14.3.0, Vulkan 1.2) et le wrapper `tools/compile-glsl-to-spirv.mjs` utilise `-V --target-env vulkan1.2 -S <stage> -o <output> <input>`; le binaire se resout via `GLSLANG_VALIDATOR` ou `tools/bin/`. Le CLI et l'erreur `MTLX_WGSL_GLSLANG_MISSING` sont valides; le binaire n'est pas installe dans l'environnement courant.
- [X] T036.3 Choisir et integrer `naga` ou `Tint` (SPIR-V -> WGSL) dans `tools/`: version figee, flags utilises, limitations connues du sous-ensemble SPIR-V accepte pour les shaders de calcul MaterialX. Naga `30.0.1` est installe sous `tools/bin/naga.exe`; `tools/naga-config.json` fige la commande `--input-kind spv <input.spv> <output.wgsl>`, le stage compute optionnel et les limitations du MVP. Le pipeline complet reste T036.4.
- [X] T036.4 Implementer `tools/transpile-glsl-to-wgsl.mjs`: GLSL genere -> SPIR-V (`glslang`) -> WGSL (`naga`/`Tint`), avec conservation des artefacts intermediaires (`.spv`, logs de validation) en cas d'echec. Le wrapper orchestre `compile-glsl-to-spirv.mjs` puis Naga 30.0.1, supporte les stages `comp|frag|vert`, `--artifacts-dir`, `--no-keep-intermediates` et les codes d'erreur GLSLang/Naga; syntaxe et chemin d'echec glslang absente valides, conversion de bout en bout en attente de `glslangValidator`.
- [X] T036.5 Aligner a la frontiere de transpilation les decorations Vulkan (`layout(set=,binding=)`, `std140`) avec les groupes/bindings du contrat WebGPU (`FrameUniforms`, `CameraUniforms`, `Light`, `BvhNode`, `TriangleIndices`, accumulation, BVH, sol, lumiere, environnement), sans renommage manuel cote JavaScript. Le contrat versionne maintenant la matrice Vulkan et `tools/validate-glsl-vulkan-contract.mjs` vérifie les 14 bindings, l'unicite des couples set/binding, `std140` pour les uniform blocks et la version GLSL Vulkan.
- [X] T036.6 Ajouter des tests qui distinguent un WGSL transpile valide d'un echec de generation GLSL, de compilation SPIR-V ou de transpilation WGSL, avec des codes `MTLX_WGSL_*` precis par etape. `tools/test-wgsl-pipeline-errors.mjs` couvre l'entrée/génération, glslang, Naga ou son blocage par glslang, et la validation du contrat WGSL avec nettoyage automatique des artefacts temporaires.
- [X] T037 Definir dans le host generator l'interface d'integration du path tracer: `mtlxGenEvaluateBsdf`, `mtlxGenSampleBsdf`, PDF, directions locales, medium et metadata de materiau, exprimee en GLSL avant transpilation.
- [X] T038 Porter les adaptations de closures necessaires aux cinq modeles MVP: `open_pbr_surface`, `standard_surface`, `disney_principled`, `gltf_pbr` et `usd_preview_surface`.
- [X] T039 Ajouter des erreurs explicites dans le host generator pour closures, sampling/pdf, ressources ou signatures non supportes, avant transpilation.
- [X] T040 Creer un contrat WGSL versionne dans `public/mtlx/` pour les entrypoints, structures, ressources, groupes/bindings, espaces de couleur et metadata, verifie sur le WGSL transpile final.
- [X] T041 Creer un validateur WGSL dedie dans `tools/` qui controle le contrat et les declarations WGSL du fichier transpile, sans reutiliser le parseur GLSL de `check-generator-abi.mjs`.
- [X] T042 Ecrire un test WASM minimal: chargement du runtime, bibliotheques standard, lecture d'un `.mtlx`, instanciation du host generator GLSL et recuperation d'une source GLSL valide destinee a la transpilation.
- [X] T043 Generer, transpiler puis valider les artefacts WGSL pour les cinq fixtures synthetiques et les cinq carpaint existants, apres T036.1-T036.6; le rapport doit conserver les erreurs detaillees par fixture et par etape (generation GLSL, compilation SPIR-V, transpilation WGSL, validation contrat). Les dix fixtures passent maintenant génération GLSL Vulkan, glslang 15.0.0, Naga 30.0.1 et validation du module MaterialX fragment; le validateur n'applique le contrat complet Frame/BVH/bindings qu'au shader hôte assemblé, pas au module MaterialX isolé.
- [X] T044 Publier atomiquement les artefacts Emscripten mis a jour (`JsMaterialXGenShader.js`, `.wasm`, `.data`), le registre, une version de runtime incrementee et la version figee du pipeline `glslang`/`naga`/`Tint` sous `public/mtlx/`. Publication `t044-2026-09-16` depuis `../MaterialX-rva/javascript/build-t036/bin`; `runtime-pipeline.json` fige glslangValidator 15.0.0, Vulkan 1.2 et Naga 30.0.1; le checker runtime et le build viewer passent.
- [X] T045 Mettre a jour `public/mtlx/PUBLISH_INFO.md`, `generator-abi-expectations.json` et/ou les nouveaux fichiers de contrat avec le host generator GLSL, la chaine de transpilation et les versions de bundle correspondantes. Publication `t044-2026-09-16` documentée avec le host Vulkan GLSL, les exports runtime, le contrat WGSL et glslang 15.0.0 -> Naga 30.0.1.

**Checkpoint WASM**: Le runtime publie expose simultanement le host GLSL existant, `MtlxPathTracerHostWgslShaderGenerator` (GLSL) et le pipeline de transpilation `glslang`/`naga`/`Tint` fige en version; tous les fixtures MVP traversent generation GLSL, compilation SPIR-V et transpilation WGSL pour produire un WGSL conforme.

---

## Phase 6: Integration MaterialX WebGPU et parite de base

**Purpose**: Connecter le dispatch WGSL genere, les resources MaterialX et l'integrateur compute sans fallback legacy.

**Depends on**: T037-T045

- [X] T046 Separer les adaptateurs viewer de generation: WebGL appelle le host GLSL actuel directement; WebGPU appelle `MtlxPathTracerHostWgslShaderGenerator` pour obtenir du GLSL, puis invoque le pipeline de transpilation `glslang`/`naga`/`Tint` avant de consommer le WGSL resultant; selection basee exclusivement sur `renderer_backend`. La route WebGPU refuse explicitement l'absence du hook de transpilation au lieu de fallback WebGL.
- [X] T047 Construire les modules WGSL finaux avec prelude commun, integrateur et artefact MaterialX transpile; verifier signatures, collisions de noms et diagnostics `getCompilationInfo()` avant creation de pipeline. `src/webgpu/wgslModuleAssembler.js` assemble prelude/integrateur/material, rejette les collisions et signatures manquantes, tandis que `WebGpuRenderer` utilise désormais le helper de compilation avec diagnostics explicites.
- [X] T048 Remplacer `extractMtlxTextureBindings()` pour WebGPU par le manifeste genere des textures/samplers/groups/bindings; garder des textures individuelles au MVP. Le manifeste WebGPU reserve les bindings 0-13 du contrat hôte et alloue chaque texture MaterialX comme paire texture/sampler à partir du binding 14, avec URL, type, source et espace couleur.
- [X] T049 Uploader et binder textures MaterialX, envmap, sol et lumières suivant le contrat WGSL; valider espace couleur, dimensions et types echantillonnables. `WebGpuRenderer.setMaterialTextureManifest()` valide les paires texture/sampler, bindings, dimensions et URLs, upload les ressources GPU et `createMaterialTextureBindGroup()` les lie à un pipeline MaterialX; le manifeste distingue les textures MaterialX couleur des données linéaires.
- [X] T050 Verifier avant pipeline les limites device `maxBindGroups`, `maxBindingsPerBindGroup` et `maxSampledTexturesPerShaderStage`; produire une erreur actionnable si le materiau les depasse. `validateMaterialTextureLimits()` vérifie aussi le nombre de samplers, les bindings MaterialX et retourne une erreur actionnable avant upload/pipeline.
- [X] T051 Propager au viewer les erreurs explicites de dispatch incomplet, closure invalide, texture absente, signature invalide ou limite de binding depassee. `src/webgpu/errorCodes.js` centralise les codes `MTLX_WGSL_*`, `main.js` les affiche dans l'overlay et l'état backend, et le test `tools/test-wgsl-error-codes.mjs` couvre les classifications.
- [ ] T052 Rendre et valider les dix fixtures MaterialX MVP en WebGPU, sans approximation ou chemin legacy; conserver un rapport par fixture. Le runner `tools/validate-webgpu-materialx-fixtures.mjs` est ajouté, mais la validation reste bloquée avant rendu : `window.__openpbrTranspileGlslToWgsl` n'est pas encore implémenté dans le navigateur, donc la route WebGPU refuse correctement le fallback WebGL. Executer T052.1-T052.8 dans l'ordre avant de cocher T052.
- [X] T052.1 Figer la matrice des dix fixtures et des URLs de rendu: associer chaque identifiant aux cinq modeles synthetiques et cinq fixtures carpaint, imposer la meme scene, camera, resolution, samples, bounces et environnement, puis vérifier que chaque fichier `.mtlx` existe avant lancement. Sortie: `artifacts/webgpu-migration/t052-fixture-matrix.json` versionne et recopie dans le rapport T052 avec `fixtureId`, `materialPath`, URL et paramètres de rendu.
- [X] T052.2 Implémenter le transpileur navigateur WebGPU: exposer `window.__openpbrTranspileGlslToWgsl` ou un adaptateur équivalent, recevoir le GLSL Vulkan produit par `MtlxPathTracerHostWgslShaderGenerator`, appeler glslang puis Naga, retourner le WGSL et préserver les logs/artefacts; propager les codes `MTLX_WGSL_GLSLANG_*` et `MTLX_WGSL_NAGA_*`. Le runner T052 expose l'adaptateur HTTP local, l'injecte avant le chargement navigateur et préserve les artefacts par fixture; syntaxe et build validés. La validation de rendu des dix fixtures reste T052.3-T052.8.
- [X] T052.3 Assembler le WGSL MaterialX au pipeline final: combiner le prelude, l'intégrateur, le module MaterialX transpile et les ressources déclarées; vérifier signatures, collisions, entry points et bindings 0-13 plus les bindings textures 14+ avant `createShaderModule`. `assembleWgslModules()` et `validateHostBindings()` vérifient désormais l'assemblage et le contrat; `tools/test-wgsl-final-assembly.mjs` couvre un fragment minimal et les collisions/signatures. La compilation WebGPU complète des dix fixtures reste T052.4-T052.8.
- [X] T052.4 Binder les ressources du fixture: charger le manifeste textures/samplers T048, uploader les images, vérifier dimensions/espace couleur, créer le bind group MaterialX et refuser toute texture absente ou binding hors limites. `setMaterialTextureManifest()` et `createMaterialTextureBindGroup()` implémentent ces contrôles; `tools/test-webgpu-material-texture-manifest.mjs` vérifie la matrice, la paire binding 14/15 et l'espace couleur avant dispatch.
- [X] T052.5 Rendre un fixture Lambert opaque minimal en WebGPU: `open_pbr_surface` passe la chaîne complète génération, pipeline, bindings, rendu normal, capture présentable et hitcheck sans fallback. Le rapport agrégé confirme `active=webgpu`, deux samples, image non uniforme, `gpuError=null`, région objet visible et `52767` pixels objet au hitcheck (`80.51605224609375%`). Les preuves détaillées sont consignées dans T052.5.1-T052.5.6.
- [X] T052.5.1 Préparer le fixture et l'environnement de rendu: lancer uniquement `open_pbr_surface` avec `standard-shader-ball`, résolution `256x256`, `max_samples=2`, environnement déterministe et transpileur HTTP local; vérifier que le fichier `.mtlx` est chargé et que le backend demandé est `webgpu`. Le mode `T052_SETUP_ONLY=1` du runner valide ce bootstrap et écrit la matrice/setup dans le rapport.
- [X] T052.5.2 Valider l'activation et les ressources WebGPU: attendre `active=webgpu`, `webgpuStatus=ready`, la création des pipelines compute/presentation, l'upload de la BVH, les textures sol/environnement et l'absence de `GPUValidationError`; enregistrer dimensions, compteurs BVH et bornes de scène. Le setup-only vérifie backend, BVH non vide, dimensions `256x256`, bind groups, texture sol, erreurs GPU/shader et bornes de scène; `open_pbr_surface` passe.
- [X] T052.5.3 Valider l'intersection géométrique de l'objet: exécuter le mode `hitcheck` et exiger une région objet rouge non vide, distincte du bleu du sol et du vert `no-hit`; vérifier si nécessaire un rayon de contrôle vers les bornes puis un rayon triangle connu avant de corriger caméra, packing ou traversée BVH. Correction appliquée: la traversée WebGPU était limitée à 64 visites contre un parcours WebGL jusqu'à épuisement de la pile; le budget est maintenant 4096. `hitcheck` produit une région rouge non vide, quantifiée par `objectHitFraction` dans le rapport.
- [X] T052.5.4 Valider le dispatch matériau Lambert: le mode normal utilise le pipeline et le bind group MaterialX sans fallback, produit un pixel d'accumulation fini/non nul et une image non uniforme sans erreur GPU. Le gate différentiel `open_pbr_surface` / `standard_surface` confirme des dispatchs distincts et une variation mesurable sur 3721 pixels. Les preuves détaillées sont consignées dans les sous-tâches T052.5.4.1-T052.5.4.5 et le rapport T052.
- [X] T052.5.4.1 Générer et tracer le dispatch MaterialX: charger `open_pbr_surface`, appeler `MtlxPathTracerHostWgslShaderGenerator`, exécuter GLSL -> SPIR-V -> WGSL et enregistrer les indicateurs `generatedWgsl`, `hostDispatch` et les erreurs par étape. Le rapport conserve maintenant `hostGlslLength`, `wgslLength`, `generatedWgsl` et `hostDispatch`; l'intégration au pipeline reste T052.5.4.2.
- [X] T052.5.4.2 Assembler le pipeline WebGPU MaterialX: le generator émet un GLSL autonome avec `Basis`, `Volume`, helpers compute et entry point de bibliothèque; glslang/Naga produit un WGSL avec bindings MaterialX 15-19, l'assembleur ajoute les bridges stables `mtlxGenEvaluateBsdf`/`mtlxGenSampleBsdf` au host compute et Chrome crée le pipeline final. Validation `open_pbr_surface`: `generatedWgsl=true`, `hostDispatch=true`, `webgpuMaterialPipeline=true`, `gpuError=null`, `fallback=false`, deux samples et runner code 0. L'activation du bind group matériau reste T052.5.4.3.
- [X] T052.5.4.3 Binder les ressources du matériau: le bind group final fusionne les ressources hôte 0-14, le bloc privé MaterialX 15, radiance/irradiance et samplers 16-19, puis les textures fichier à partir de 20. Le pipeline ne devient actif qu'après présence de tous les bindings déclarés; les changements de textures recréent le groupe atomiquement. Validation Chrome `open_pbr_surface`: `materialBindGroup=true`, `materialPipelineActive=true`, buffer privé présent, bindings 15-19, deux samples, `gpuError=null`, `fallback=false`, aucune texture détruite ni erreur de submit. Ce fixture sans texture fichier utilise les ressources environnement de repli 1x1; l'upload HDR natif reste hors de cette sous-tâche.
- [X] T052.5.4.4 Rendre le matériau Lambert: le bridge initialise les paramètres privés MaterialX par invocation avant `mtlxGenEvaluateBsdf`/`mtlxGenSampleBsdf`, puis le mode normal soumet le pipeline MaterialX actif et attend `queue.onSubmittedWorkDone()`. Validation Chrome `open_pbr_surface`: objet visible et ombré, `samples=2`, `active=webgpu`, pipeline/bind group actifs, pixel `[0.201171875, 0.201171875, 0.201171875, 1]` fini et non nul, variance `272.619977828115`, `gpuError=null`, `fallback=false`, runner code 0.
- [X] T052.5.4.5 Fermer le gate matériau: le runner accepte une paire ciblée et enregistre les hashes SHA-256 GLSL/WGSL ainsi qu'une comparaison RGB des captures. Validation Chrome `open_pbr_surface` / `standard_surface`: deux pipelines et bind groups actifs, deux samples chacun, `gpuError=null`, `fallback=false`, hashes GLSL/WGSL distincts, différence RGB moyenne `0.2701873779296875`, `3721/65536` pixels modifiés (`5.67779541015625%`) et `materialComparison.pass=true`. T052.5.4 est fermé.
- [X] T052.5.5 Produire une capture présentable: le runner attend deux samples et `queue.onSubmittedWorkDone()`, masque puis vérifie `progress_overlay`, lil-gui, compteur, info et overlay d'erreur, et conserve séparément les PNG canvas/viewport avec dimensions et SHA-256. Validation Chrome `open_pbr_surface`: `gpuWorkCompleted=true`, `uiHidden=true`, `captures.valid=true`, objet visible (`contraste centre/bordure=7.091816644149944`, fraction centrale sombre `0.27943615257048093`), image non uniforme, `gpuError=null`, `fallback=false`, runner code 0. Le viewport masqué étant exactement le canvas 256x256, les pixels/hash peuvent légitimement être identiques malgré deux chemins de fichiers distincts.
- [X] T052.5.6 Fermer le gate de la sous-tâche: le mode `T052_CLOSE_GATE=1` agrège rendu normal et hitcheck dans un seul rapport sans écrasement. Validation Chrome `open_pbr_surface`: variance RGB `273.20687086787075`, image non uniforme, hitcheck `52767/65536` pixels objet (`0.8051605224609375`), `active=webgpu`, deux samples normal et hitcheck, `gpuError=null`, `fallback=false`, `presentationPass=true`, `uiHidden=true`, objet visible et trois captures conservées (`-webgpu.png`, `-webgpu-viewport.png`, `-webgpu-hitcheck.png`). T052.5 est fermé.
- [X] T052.6 Rendre les quatre autres fixtures synthétiques (`standard_surface`, `disney_principled`, `gltf_pbr`, `UsdPreviewSurface`): le runner isolé `validate:webgpu-materialx-synthetic` produit un rapport par fixture puis agrège les quatre résultats dans `t052.6-synthetic-fixtures-report.json`. Toutes passent avec backend WebGPU, pipeline/bind group MaterialX actifs, deux samples, captures 256x256 non uniformes, `gpuError=null` et `fallback=false`. Durées génération/transpilation/pipeline/total (ms): standard `1907.8/1035.1/50691.6/70307.8`, Disney `1781/1088.8/85803.4/105173.2`, glTF `1797.7/1031.9/50368/69079.4`, USD `1832/1010.4/51627.8/69956.9`. La capture USD chrome reste presque noire car l'environnement HDR WebGPU utilise encore le repli 1x1; cette divergence visuelle est explicitement laissée au gate de parité T053, pas masquée comme une parité acquise.
- [ ] T052.7 Rendre les cinq fixtures carpaint (`carpaint`, `glass`, `pearl`, `soapbubble`, `synthetic_default`): appliquer les mêmes contrôles sans désactiver les closures ou remplacer le matériau par une BRDF legacy; documenter toute closure ou texture non supportée avec un code d'erreur précis.
- [ ] T052.8 Produire le rapport final et le gate: écrire `artifacts/webgpu-migration/webgpu-materialx-fixtures-report.json` avec les dix résultats et les erreurs par étape, conserver les captures PNG, exécuter `npm run build` et ne marquer T052 terminée que si les dix fixtures ont `generation=pass`, `spirv=pass`, `transpile=pass`, `pipeline=pass`, `render=pass` et `fallback=false`.
- [ ] T053 Comparer les captures WebGPU MaterialX aux baselines WebGL en utilisant les seuils de T006 et expliciter chaque divergence acceptee. `tools/compare-webgpu-materialx-baselines.mjs` et `artifacts/webgpu-migration/webgpu-materialx-baseline-comparison.json` sont en place; la validation reste bloquée tant que les cinq captures WebGPU MaterialX correspondantes ne sont pas produites.

**Checkpoint**: `Pathtracer MTLX` WebGPU utilise exclusivement la generation WASM WGSL et atteint la parite visuelle de base avec WebGL.

---

## Phase 7: Parite OpenPBR avancee

**Purpose**: Porter les comportements OpenPBR v1.2 et les fonctionnalités spectrales apres validation de la parite MaterialX de base.

**Depends on**: T052-T053

- [ ] T054 Porter et comparer coat darkening, Fresnel F82 borne, clamping d'entrees, `specular_weight`/IOR, transmission scatter, thin-walled et subsurface.
- [ ] T055 Porter thin film spectral et dispersion, y compris la strategie hero wavelength et le controle de double ponderation spectrale.
- [ ] T056 Porter haze dual-lobe et retroreflectivite seulement quand la reference WebGL et le contrat de parametres sont complets.
- [ ] T057 Diagnostiquer le chemin CDF envmap surexpose cote WebGL; ne le porter/activer cote WebGPU qu'apres correction et comparaison isolee.
- [ ] T058 Ajouter une matrice de parite par modele MaterialX et parametre: non applicable, implemente, compare, accepte.
- [ ] T059 Executer la matrice de validation des materiaux et scenes reelles, puis mettre a jour les baselines si une correction WebGL rend cela necessaire.

**Checkpoint**: Toute fonctionnalite declaree WebGPU est tracee dans la matrice de parite et ne depend d'aucun shader legacy.

---

## Phase 8: Rasterizer, automatisation et publication

**Purpose**: Finaliser l'experience utilisateur, automatiser la validation et decider la disponibilite du rasterizer WebGPU.

**Depends on**: T059

- [ ] T060 Evaluer un pipeline render WGSL pour le rasterizer WebGPU avec criteres de performance et de parite; ne pas utiliser le path tracer a un sample comme remplacement.
- [ ] T061 Implementer le rasterizer WebGPU si l'evaluation T060 est acceptee; conserver la separation entre pipeline render et pipeline compute.
- [ ] T062 Ajouter le selecteur `WebGL2`/`WebGPU` au GUI, son etat indisponible et les diagnostics de backend actifs.
- [ ] T063 Ajouter l'instrumentation de chargement scene, creation buffers, uploads, generation/pipeline WGSL, temps GPU et vitesse de convergence; utiliser `GPUQuerySet` quand disponible.
- [ ] T064 Etendre `launch_render.mjs` avec `--backend=webgpu`, attente fiable du compteur WebGPU, capture et export des diagnostics adapter/device.
- [ ] T065 Ajouter les suites de captures WebGPU sur les scenes de reference et les comparaisons automatisees contre les manifests baseline.
- [ ] T066 Tester changements repetes de scene, materiau, backend et resize pour detecter pertes de device, erreurs de validation et fuites de ressources.
- [ ] T067 Documenter support navigateur/GPU, limitations, chemin de repli WebGL2 et commandes de validation dans `README.md` et les specifications associees.
- [ ] T068 Executer la validation finale: build Vite, contrat WASM/WGSL, captures WebGL de non-regression et captures WebGPU de parite.

**Checkpoint final**: WebGPU est publiable pour la matrice de plateformes validee; WebGL2 reste le chemin par defaut tant que cette matrice ne couvre pas les environnements cibles.

---

## Dependances et parallelisme

### Chaine critique

`T001/T007 -> T008-T015 -> T016-T025 -> T026-T033 -> T034-T045 -> T046-T053 -> T054-T059 -> T060-T068`

### Travail parallelisable

- T002, T003 et T006 peuvent avancer avec T001.
- T009 peut avancer avec T008; T010 commence apres T008.
- T017 peut avancer avec T016; T018 et T019 peuvent avancer apres T016.
- T028, T029 et T030 peuvent avancer apres T026-T027.
- T040 et T041 peuvent avancer avec T034-T039, mais doivent etre finalises avant T042-T043.
- T044 et T045 commencent apres T043.
- T048 et T050 peuvent avancer avec T047; ils doivent etre termines avant la validation T052.
- T062, T063 et T064 peuvent avancer apres que le backend WebGPU est integre; T065-T068 attendent leur resultat.

## Strategie de livraison

1. Livrer la Phase 2 en premier: un WebGPU smoke test confirme la disponibilite navigateur et le cycle de vie du device sans risquer l'integrateur.
2. Livrer ensuite les Phases 3 et 4 pour obtenir un path tracer WGSL de reference sans MaterialX.
3. Traiter la Phase 5 comme un jalon cross-repo bloque: aucun dispatch WebGPU MaterialX dans le viewer avant publication et validation du bundle WASM.
4. Activer `Pathtracer MTLX` WebGPU seulement apres T052-T053, puis porter les effets OpenPBR avances.
5. Garder le rasterizer WebGPU hors du chemin critique jusqu'a ce que le compute path tracer soit stable et mesure.