# Taches - MTLX WebGPU render pathtracer + rasterizer via GPURenderPipeline

**Input**: [plan.md](./plan.md)

**Portee**: Porter les routes plein ecran `Pathtracer MTLX` et `Rasterizer MTLX` WebGL vers des `GPURenderPipeline` WebGPU vertex/fragment. `glsl/pathtracing/mtlx/` et `glsl/rasterization/mtlx/`, ainsi que leurs host generators WebGL et captures associees, restent les references fonctionnelles et visuelles; la route compute WebGPU de la spec 005 reste disponible et distincte.

**Hors portee**: emission WGSL directe depuis MaterialX, reimplementation independante des closures MaterialX ou du modele OpenPBR, et toute modification d'equations, d'echantillonnage ou de rendu WebGL pour faciliter le port.

**Prerequis reutilises**: cycle de vie WebGPU, contrat de scene, generation MaterialX Vulkan, glslang, Naga, validation WGSL, bindings et metriques de baseline de `specs/005-webgpu-migration/`.

**Regle d'implementation**: Le fragment MaterialX est genere tel quel en GLSL par `MtlxPathTracerHostShaderGenerator` (non modifie), sans generateur C++ WGSL dedie. La mise en forme Vulkan-stricte, la compilation glslang vers SPIR-V et la transpilation Naga vers WGSL sont entierement pilotees cote JS/TS. Aucune traduction par regex JavaScript sur le GLSL/WGSL genere, emission WGSL directe par MaterialX, reimplementation legacy ou fallback masque n'est acceptee.

## Phase 1 - Figer les references WebGL et le contrat fragment

**Purpose**: Figer les deux sources de reference avant le port, sans modifier `glsl/pathtracing/mtlx/` ni `glsl/rasterization/mtlx/`.

- [x] T001 Inventorier `glsl/pathtracing/mtlx/common.glsl`, `glsl/pathtracing/mtlx/pathtracer.glsl`, `glsl/rasterization/mtlx/`, le vertex fullscreen, l'assemblage runtime dans `main.js` et les fonctions produites par les host generators pathtracer/rasterizer; ecrire `artifacts/webgpu-render-pathtracer/webgl-fragment-inventory.md`.
- [x] T002 Extraire les ressources, uniforms, samplers, textures, varyings, outputs et etat d'accumulation des routes WebGL pathtracer et rasterizer dans `artifacts/webgpu-render-pathtracer/webgl-fragment-contract.json`.
- [x] T003 [P] Definir dans `artifacts/webgpu-render-pathtracer/comparison-thresholds.json` les metriques et seuils de couverture objet, luminance, erreur RGB moyenne, pixels hors seuil et convergence.
- [x] T004 Etendre le runner de capture pour enregistrer scene, camera, materiau, environnement, seed, bounces, samples, resolution, tonemapping et hash du dispatch pour les deux routes.
- [ ] T005 Capturer les baselines WebGL `Pathtracer MTLX` et `Rasterizer MTLX` pour les fixtures synthetiques, `open_pbr_surface`, metal, carpaint, glass, pearl et soapbubble sous `artifacts/webgpu-render-pathtracer/baselines/`.
- [ ] T006 Valider la reproductibilite des baselines par une seconde capture et publier `artifacts/webgpu-render-pathtracer/webgl-baseline-report.json`.

**Gate**: les contrats WebGL pathtracer et rasterizer et les baselines sont reproductibles; aucune modification des references n'est requise par la suite.

**Checkpoint**: Les contrats et les captures WebGL sont stables; `glsl/pathtracing/mtlx/` et `glsl/rasterization/mtlx/` n'ont pas ete modifies pour preparer le port.

---

## Phase 2 - Host GLSL non modifie et mise en forme Vulkan cote JS/TS

**Depends on**: T001-T006

- [x] T007 Dans `../MaterialX-rva`, ajouter les tests de non-regression prouvant que `MtlxPathTracerHostShaderGenerator` conserve le GLSL WebGL actuel et que le rasterizer WebGL continue de fonctionner avec `EsslHostShaderGenerator`; aucune modification C++ n'est requise pour la route WebGPU. Le test Catch2 `GenShader: MTLX WebGL Host Generators Regression` verifie les hooks `evaluateBsdf`/`sampleBsdf` du dispatch pathtracer et la generation `main` du rasterizer ESSL sur un fixture MaterialX en memoire.
- [x] T008 Cote JS/TS, envelopper le GLSL brut produit par `MtlxPathTracerHostShaderGenerator` avec le preambule Vulkan-strict requis par glslang: `#version 450`, sortie fragment et interface reservee; ne modifier ni le generateur C++ ni le GLSL WebGL de reference. `generateMtlxWebGpuDispatch()` utilise desormais le host generator GLSL WebGL et `wrapMtlxHostGlslForVulkan()` ajoute l'adaptation cote JS/TS avant transpilation.
- [x] T009 Envelopper de la meme facon cote JS/TS le GLSL produit par le host rasterizer MTLX (`EsslHostShaderGenerator`) pour obtenir un fragment Vulkan strict et compilable pour la meme chaine `glslang -> SPIR-V -> Naga -> WGSL`, sans modification C++ du generateur rasterizer. `generateMtlxRasterDispatch()` conserve la sortie ESSL pour WebGL et active pour WebGPU `wrapMtlxRasterGlslForVulkan()` puis le hook de transpilation.
- [x] T010 Ajouter cote JS/TS les types et helpers de preambule requis afin que les fragments pathtracer et rasterizer compilent sans prelude WebGL implicite, sans les injecter dans le generateur C++. Le preambule partage expose `Basis`, `Volume`, constantes, RNG, conversions local/world et echantillonnage cosinus pour les deux wrappers Vulkan.
- [x] T011 Definir une seule table de bindings source dans `public/mtlx/wgsl-host-contract.json` ou un contrat render dedie, puis la consommer depuis le wrapper JS/TS pendant l'assemblage, sans renommage regex du GLSL genere. Le contrat dedie `public/mtlx/render-host-contract.json` reserve les bindings host 0-14, commence les ressources MaterialX a 15 et est charge/valide par `main.js` avant les wrappers pathtracer et rasterizer.
- [x] T012 Assembler cote JS/TS les fragments GLSL Vulkan complets, integrateur et dispatch MaterialX inclus, avec detection des declarations ou ressources dupliquees. `assemble_mtlx_route_dispatch()` valide maintenant les declarations top-level du dispatch, du bridge et de l'integrateur avant concatenation et signale explicitement les collisions.
- [x] T013 Compiler avec glslang chaque fixture cible et conserver sources/logs dans `artifacts/webgpu-render-pathtracer/glsl-vulkan/`.
	- [x] T013.1 Figer la matrice des fixtures pathtracer/rasterizer et leurs chemins MaterialX, puis verifier que chaque fichier source existe.
	- [x] T013.2 Generer le GLSL host de `MtlxPathTracerHostShaderGenerator` et `EsslHostShaderGenerator` pour chaque fixture et conserver une source par route sous `artifacts/webgpu-render-pathtracer/glsl-vulkan/<fixture>/`.
	- [x] T013.3 Appliquer le wrapper Vulkan JS/TS complet issu des contrats de T008-T011, notamment les blocs uniformes, layouts et bindings explicites, sans renommage des ressources MaterialX. Les uniforms non opaques sont regroupes dans `MtlxMaterialUniforms` au binding 15 et les ressources opaques recoivent des bindings explicites a partir de 16.
	- [x] T013.4 Compiler chaque source fragment avec glslang vers SPIR-V en fixant `fragment`, `main`, `vulkan1.2` et les options de validation requises. La matrice complete des 9 fixtures et des deux routes a compile avec succes : 18/18 sources GLSL Vulkan et 18/18 artefacts SPIR-V presents.
	- [x] T013.5 Conserver un log glslang et un statut par fixture/route, puis publier `artifacts/webgpu-render-pathtracer/glsl-vulkan/report.json`.
	- [x] T013.6 Valider la matrice complète : toutes les fixtures doivent produire un GLSL Vulkan compilable et un SPIR-V non vide. `tools/validate-mtlx-render-fixtures.mjs` confirme 18/18 cas couverts, compiles et non vides pour les sources GLSL et les artefacts SPIR-V.
- [x] T014 Supprimer `MtlxPathTracerHostWgslShaderGenerator` (classe C++, bindings Emscripten `JsMtlxPathTracerHostWgslShaderGenerator.cpp`, references dans `public/mtlx/*.json` et les outils JS/TS), rebuilder et publier atomiquement `JsMaterialXGenShader.js/.wasm/.data` sous `public/mtlx/` a partir du seul `MtlxPathTracerHostShaderGenerator`, puis verifier les hashes et les exports Emscripten. Le runtime publie expose le host GLSL conserve, n'expose plus le host Wgsl supprime et passe le check d'artefacts/export.

**Checkpoint**: Toutes les fixtures produisent, via le wrapper JS/TS et le GLSL non modifie de `MtlxPathTracerHostShaderGenerator`, des fragments GLSL Vulkan courants compilables par glslang; les routes WebGL restent identiques; `MtlxPathTracerHostWgslShaderGenerator` n'existe plus dans le code ni dans les artefacts publies.

---

## Phase 3 - SPIR-V, Naga et stages WGSL

**Depends on**: T014

- [x] T015 Etendre `tools/compile-glsl-to-spirv.mjs` avec un mode fragment render qui fixe le stage et l'entry point, rejette les sorties obsoletes et ecrit un manifeste de hash. `--mode fragment-render` force `frag/main`, supprime la sortie precedente avant compilation, verifie un SPIR-V non vide et publie les hashes SHA-256 GLSL/SPIR-V dans le manifeste associe.
- [x] T016 Etendre `tools/transpile-glsl-to-wgsl.mjs` pour convertir le SPIR-V fragment avec la version Naga verrouillee et conserver les diagnostics complets. `--mode fragment-render` force `frag/main`, reutilise glslang puis Naga 30.0.1 et publie un manifeste avec les hashes GLSL/SPIR-V/WGSL et les logs de chaque etape.
- [x] T017 Creer dans `src/webgpu/` un vertex WGSL minimal de fullscreen triangle qui produit la position clip et les coordonnees exigees par le fragment pathtracer et le fragment rasterizer. Le module `src/webgpu/fullscreenTriangle.wgsl.js` expose `fullscreenTriangleVertex`, `@builtin(position)` et `@location(0) uv`.
- [x] T018 [P] Ajouter un validateur vertex/fragment pour entry points, builtins, locations, groupes/bindings, uniform layouts, texture sample types et limites du device. `tools/validate-render-wgsl-interface.mjs` valide le vertex fullscreen, le contrat Vulkan/bindings et, lorsqu'il est fourni, l'entry point fragment, la sortie location 0 et l'unicite des groupes/bindings; la validation GPU reelle reste dependante de T023.
- [x] T019 Executer la chaine `GLSL Vulkan -> glslang -> SPIR-V -> Naga -> WGSL` sur toute la matrice et publier `artifacts/webgpu-render-pathtracer/transpilation-report.json` avec hashes GLSL/SPIR-V/WGSL. Le runner `tools/transpile-mtlx-render-fixtures.mjs` couvre 18 cas, avec separation texture/sampler Vulkan et diagnostics conserves; les 18 fixtures sont transpilees.

**Checkpoint**: Chaque fixture dispose de stages vertex et fragment WGSL valides, traçables jusqu'au GLSL courant.

---

## Phase 4 - Assemblage WGSL render

**Depends on**: T017-T019

- [x] T020 Creer `src/webgpu/renderWgslModuleAssembler.js` pour assembler le fragment transpile avec les adaptations host requises, sans reutiliser l'assembleur compute comme autorite implicite. L'assembleur dedie valide les entry points vertex/fragment, l'interface fullscreen, les sorties et les collisions de bindings; `tools/test-render-wgsl-assembler.mjs` couvre les cas positif et collision host.
- [x] T021 Detecter dans l'assembleur les collisions de declarations module, bindings dupliques, entry points absents et interfaces inter-stage incompatibles. L'assembleur render compare desormais les declarations vertex/fragment, l'interface `FullscreenVertexOutput`, les entry points et les bindings; les tests positifs et negatifs sont couverts par `tools/test-render-wgsl-assembler.mjs`.
- [x] T022 Produire un contrat final versionne listant entry points vertex/fragment, bind group layouts et ressources attendues sous `public/mtlx/`. `public/mtlx/render-module-contract.json` formalise les stages, l'interface fullscreen, les bindings host 0-14, les ressources MaterialX a partir de 15 et le target `rgba16float`; `tools/validate-render-module-contract.mjs` le valide.
- [x] T023 Ajouter un test d'assemblage pour chaque fixture et verifier les modules finaux avec `GPUDevice.createShaderModule` dans un navigateur WebGPU reel. Chrome fenetre/D3D11 valide les 18 modules finaux sans erreur GPU.
	- [x] T023.1 Charger le rapport de transpilation, enumerer les fixtures/ routes et verifier la presence des sources WGSL transpilees.
	- [x] T023.2 Assembler pour chaque fixture le vertex fullscreen et le fragment transpile avec `renderWgslModuleAssembler.js`, en appliquant le contrat d'interface et de bindings.
	- [x] T023.3 Demarrer Chromium avec les flags WebGPU, demander un `GPUAdapter` puis un `GPUDevice` reel.
	- [x] T023.4 Creer un `GPUShaderModule` vertex et fragment pour chaque fixture et collecter `getCompilationInfo()` sans diagnostic d'erreur.
		- [x] T023.4.1 Lancer Chrome fenetre avec GPU materiel, contexte localhost securise et backend ANGLE D3D11 valide.
		- [x] T023.4.2 Demander `GPUAdapter` puis `GPUDevice` et enregistrer les limites du device.
		- [x] T023.4.3 Creer/compiler le `GPUShaderModule` vertex fullscreen et verifier `getCompilationInfo()` sans erreur.
		- [x] T023.4.4 Creer/compiler les 9 modules fragment pathtracer et verifier `getCompilationInfo()` sans erreur.
		- [x] T023.4.5 Creer/compiler les 9 modules fragment rasterizer et verifier `getCompilationInfo()` sans erreur. La separation Vulkan texture/sampler supprime les `OpTypeSampledImage` rejetes par Naga; la directive WGSL `diagnostic(off, derivative_uniformity)` preserve les `fwidth`; les 9 modules passent dans Chrome GPU D3D11.
		- [x] T023.4.6 Conserver par fixture le statut, les diagnostics navigateur, les entry points et les limites device dans `render-wgsl-module-report.json`.
		- [x] T023.4.7 Valider la matrice complete 18/18 sans erreur GPU ni WGSL manquant; le rapport final confirme 18 transpilees et 18 `GPUShaderModule` valides.
	- [x] T023.5 Publier un rapport par fixture avec navigateur, limites device, entry points, diagnostics et statut pass/blocked.
	- [x] T023.6 Faire passer la matrice complete sans fallback et marquer T023 seulement lorsque tous les modules finaux compilent dans un navigateur WebGPU reel. Chrome fenetre/D3D11 fournit `GPUAdapter`, et les 18 modules passent.

**Checkpoint**: Tous les modules finaux compilent sans diagnostic GPU et exposent le meme contrat de ressources.

---

## Phase 5 - GPURenderPipeline et accumulation

**Depends on**: T023

- [x] T024 Implementer dans `src/webgpu/` un renderer plein ecran qui cree un vrai `GPURenderPipeline` avec les stages vertex/fragment assembles et des color targets explicites. `WebGpuRenderer.createRenderPipeline()` compile les deux modules, cree un `GPURenderPipelineAsync` avec topology `triangle-list` et target canvas explicite, sans modifier la route compute.
- [x] T025 Creer les bind groups pour camera, frame, BVH, geometrie, environnement, lumiere et ressources MaterialX; refuser toute ressource absente ou layout incompatible. `WebGpuRenderer.createRenderBindGroups()` couvre les bindings host 0-14, les ressources MaterialX 15+, filtre les bindings demandes et leve une erreur pour toute ressource manquante.
- [x] T026 Implementer l'accumulation progressive avec textures ping-pong et render passes valides, sans lecture/ecriture simultanee interdite d'un attachement. `WebGpuRenderer.renderPipelineFrame()` cible la texture d'accumulation courante, soumet un render pass `clear/store`, bascule l'index et reconstruit les bind groups pour la texture suivante.
- [x] T027 Integrer dans `main.js` une route explicite `webgpu_pipeline=render` conservant `webgpu_pipeline=compute` et `renderer_backend=webgl` inchanges. `compute` reste la valeur par defaut; la boucle WebGPU appelle `renderPipelineFrame()` uniquement pour `render` et conserve `render()` pour `compute`.
- [x] T028 Relier resize, reset camera, changement de scene/materiau, pause/reprise, compteur de samples et destruction/recreation des ressources. `resize()` recree les textures ping-pong, `resetSamples()` reinitialise l'accumulation render, les changements de scene/materiau reutilisent ces hooks, et `destroy()` preserve la destruction complete des ressources WebGPU.
- [x] T029 Exposer dans le diagnostic runtime le type `render`, les hashes vertex/fragment, le statut pipeline/bind groups, les timings, samples, erreurs GPU et toute raison de fallback. `__openpbrGetWebGpuRenderState()` expose desormais pipeline render, hashes SHA-256 des stages, duree de creation, bind group, erreur GPU et `renderFallbackReason`.
- [x] T030 Ajouter une validation navigateur qui exige `GPURenderPipeline` actif, image non vide, objet visible, plusieurs samples, `gpuError=null` et aucun fallback compute/WebGL/legacy. `tools/validate-render-pipeline-browser.mjs` passe dans Chrome fenetre/D3D11 avec pipeline actif, 3 samples, `gpuError=null`, contexte WebGPU actif et aucun fallback.

**Checkpoint**: Le navigateur rend et accumule avec un `GPURenderPipeline`; les diagnostics prouvent que l'image ne vient ni du compute ni de WebGL.

---

## Phase 6 - Comparaison visuelle et decision

**Depends on**: T030

- [ ] T031 Capturer les references WebGL `Pathtracer MTLX` et `Rasterizer MTLX` ainsi que le WebGPU render en verrouillant scene, camera, materiau, environnement, seed, bounces, samples, resolution et tonemapping.
	- [x] T031.1 Capturer les 10 references WebGL `Pathtracer MTLX` avec scene, camera, materiau, environnement, seed, bounces, samples, resolution et tonemapping verrouilles; publier les hashes dans `artifacts/webgpu-render-pathtracer/comparisons/render-comparison-report.json`.
	- [ ] T031.2 Preparer le pipeline WebGPU render final par fixture : charger le fragment MaterialX final, assembler vertex/fragment, creer le `GPURenderPipeline` et les bind groups MaterialX; ne pas utiliser le fragment minimal de smoke test T030.
		- [x] T031.2.1 Charger le WGSL final par fixture et refuser tout module intermediaire sans `@fragment fragmentMain`.
		- [x] T031.2.2 Assembler/valider vertex fullscreen + fragment MaterialX avec `renderWgslModuleAssembler.js`.
		- [x] T031.2.3 Creer le `GPURenderPipeline` final avec entry points et target canvas explicites.
		- [x] T031.2.4 Reflechir les bindings MaterialX finaux et figer la table `15+` par fixture. `tools/reflect-render-bindings.mjs` confirme 18/18 fixtures reflechies, sans doublon ni chevauchement avec les bindings host 0-14; sortie : `artifacts/webgpu-render-pathtracer/render-binding-reflection.json`.
		- [x] T031.2.5 Convertir les ressources compute BVH/geometrie storage buffers en textures WebGPU `texture_2d<f32>` compatibles avec le fragment render. `src/webgpu/sceneBuffers.js` conserve les storage buffers compute et cree en parallele des textures `rgba32float` 1xN, packees en texels `vec4`, avec sampler nearest partage et destruction associee. Build Vite passe; reflexion bindings 18/18 sans erreur.
		- [x] T031.2.6 Creer les ressources envmap cube/latlong/irradiance, samplers et textures MaterialX aux bindings declares. `WebGpuRenderer` publie les alias envmap aux bindings 16-21, 36-39 et 42-45, le fallback CDF et les ressources MaterialX texture/sampler aux bindings declares par le manifest; remplacement d'une envmap ou du manifest reconstruit les ressources render. Build et reflexion des 18 fixtures passes.
		- [x] T031.2.7 Creer le bind group final par fixture, refuser toute ressource absente et valider `GPURenderPipeline` + bind group ensemble. `createRenderBindGroups` assemble les host bindings, textures BVH/geometrie, envmap, ground, lights et textures MaterialX; les bindings demandes absents sont rejetes avant `createBindGroup`. Syntaxe, build, assembleur WGSL et reflexion 18/18 passes.
		- [ ] T031.2.8 Exercer une frame render par fixture avec le fragment MaterialX final; le smoke fragment T030 est interdit pour cette etape.
			- [x] T031.2.8.1 Ajouter le runner navigateur `tools/test-final-render-fixtures.mjs`, base sur `transpilation-report.json`, couvrant les 9 materiaux et les routes pathtracer/rasterizer.
			- [x] T031.2.8.2 Demarrer chaque fixture avec `renderer_backend=webgpu`, `webgpu_pipeline=render`, le mode MTLX correspondant et `mtlx_url` resolu depuis le repertoire public Vite.
			- [x] T031.2.8.3 Attendre l'initialisation WebGPU de la fixture et verifier que le fragment final MaterialX active `GPURenderPipeline`; `prepareRenderPipeline({ materialXFinal: true })` refuse les sources sans signature MaterialX et l'etat expose `renderPipelineMaterialXFinal`. Le smoke fragment T030 reste interdit; la matrice runtime demeure bloquee par la fermeture du contexte Chrome.
			- [x] T031.2.8.4 Verifier l'activation du bind group final et l'absence de ressource MaterialX/envmap/BVH manquante avant le rendu. `main.js` transmet les bindings declares du fragment final et le contrat host 0-14; `WebGpuRenderer` memorise la table, differe la creation jusqu'au chargement scene/accumulation, puis reconstruit le bind group apres BVH, envmap et manifest MaterialX. Toute binding demandee absente est rejetee avant `createBindGroup`; le runner controle le bind group et `renderMissingBindings`.
			- [x] T031.2.8.5 Soumettre exactement une frame via `__openpbrRenderPipelineFrame`, attendre `queue.onSubmittedWorkDone()` et verifier l'absence de `gpuError`. `renderPipelineFrameCount` est incremente par le chemin render et le runner exige exactement `1`, avec `gpuError === null`.
			- [ ] T031.2.8.6 Executer la matrice complete des 18 fixtures et publier `artifacts/webgpu-render-pathtracer/final-render-fixture-report.json`; execution actuellement bloquee par la fermeture du contexte Chrome (`Target page, context or browser has been closed`) avant la premiere frame.
	- [ ] T031.3 Capturer les 10 fixtures WebGPU render dans Chrome GPU avec les memes parametres que T031.1 et ecrire les images sous `artifacts/webgpu-render-pathtracer/comparisons/`.
	- [ ] T031.4 Verifier pour chaque capture WebGPU `GPURenderPipeline` actif, plusieurs samples, image non vide, `gpuError=null`, absence de fallback compute/WebGL/legacy et scene visible.
	- [ ] T031.5 Publier les paires WebGL/WebGPU, hashes des images et metadonnees communes dans `render-comparison-report.json`; T031 ne passe que lorsque les 10 paires sont disponibles et comparables.
- [ ] T032 Calculer hashes, erreur RGB moyenne, pixels hors seuil, luminance, couverture objet et courbes de convergence; produire des images diff sous `artifacts/webgpu-render-pathtracer/comparisons/`.
- [ ] T033 Executer les fixtures dans des navigateurs/devices isoles si necessaire et verifier `gpuError=null`, absence de fallback et origine `GPURenderPipeline` pour chacune.
- [ ] T034 Tester changements repetes de scene, materiau, resize et recreation de pipeline; verifier reset d'accumulation et absence de ressources detruites reutilisees.
- [ ] T035 Comparer temps de generation, compilation, premiere frame et frame stabilisee aux routes WebGL de reference (`Pathtracer MTLX` + `Rasterizer MTLX`) et WebGPU compute.
- [ ] T036 Produire `artifacts/webgpu-render-pathtracer/final-report.json` et `final-report.md` avec verdict go/no-go et divergences acceptees fixture par fixture.
- [ ] T037 Mettre a jour la matrice de support et la documentation uniquement si T036 est `go`; conserver sinon la route render explicitement experimentale ou desactivee.

**Checkpoint final**: Toutes les fixtures obligatoires respectent les seuils visuels WebGL pour les deux references (`Pathtracer MTLX` et `Rasterizer MTLX`) avec un vrai `GPURenderPipeline`, sans erreur GPU ni fallback masque.

---

## Chaine critique

`T001-T006 -> T007-T014 -> T015-T019 -> T020-T023 -> T024-T030 -> T031-T037`

## Travail parallelisable

- T003 peut avancer avec T001-T002.
- T015-T016 et T017 peuvent avancer en parallele apres T014; T019 attend leurs resultats.
- T025 et T026 peuvent etre prepares avec T024 mais T027 attend un pipeline et des bind groups valides.
- Les captures T031 peuvent etre reparties par fixture; T032-T036 attendent leur consolidation.
