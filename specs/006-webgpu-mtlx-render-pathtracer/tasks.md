# Taches - MTLX WebGPU render pathtracer + rasterizer via GPURenderPipeline

**Input**: [plan.md](./plan.md)

**Portee**: Porter les routes plein ecran `Pathtracer MTLX` et `Rasterizer MTLX` WebGL vers des `GPURenderPipeline` WebGPU vertex/fragment. `glsl/pathtracing/mtlx/` et `glsl/rasterization/mtlx/`, ainsi que leurs host generators WebGL et captures associees, restent les references fonctionnelles et visuelles; la route compute WebGPU de la spec 005 reste disponible et distincte.

**Hors portee**: emission WGSL directe depuis MaterialX, reimplementation independante des closures MaterialX ou du modele OpenPBR, et toute modification d'equations, d'echantillonnage ou de rendu WebGL pour faciliter le port.

**Prerequis reutilises**: cycle de vie WebGPU, contrat de scene, generation MaterialX Vulkan, glslang, Naga, validation WGSL, bindings et metriques de baseline de `specs/005-webgpu-migration/`.

**Regle d'implementation**: Le fragment MaterialX est genere en GLSL Vulkan, compile par glslang vers SPIR-V, puis transpile par Naga vers WGSL. Aucune traduction par regex JavaScript, emission WGSL directe par MaterialX, reimplementation legacy ou fallback masque n'est acceptee.

## Phase 1 - Figer les references WebGL et le contrat fragment

**Purpose**: Figer les deux sources de reference avant le port, sans modifier `glsl/pathtracing/mtlx/` ni `glsl/rasterization/mtlx/`.

- [ ] T001 Inventorier `glsl/pathtracing/mtlx/common.glsl`, `glsl/pathtracing/mtlx/pathtracer.glsl`, `glsl/rasterization/mtlx/`, le vertex fullscreen, l'assemblage runtime dans `main.js` et les fonctions produites par les host generators pathtracer/rasterizer; ecrire `artifacts/webgpu-render-pathtracer/webgl-fragment-inventory.md`.
- [ ] T002 Extraire les ressources, uniforms, samplers, textures, varyings, outputs et etat d'accumulation des routes WebGL pathtracer et rasterizer dans `artifacts/webgpu-render-pathtracer/webgl-fragment-contract.json`.
- [ ] T003 [P] Definir dans `artifacts/webgpu-render-pathtracer/comparison-thresholds.json` les metriques et seuils de couverture objet, luminance, erreur RGB moyenne, pixels hors seuil et convergence.
- [ ] T004 Etendre le runner de capture pour enregistrer scene, camera, materiau, environnement, seed, bounces, samples, resolution, tonemapping et hash du dispatch pour les deux routes.
- [ ] T005 Capturer les baselines WebGL `Pathtracer MTLX` et `Rasterizer MTLX` pour les fixtures synthetiques, `open_pbr_surface`, metal, carpaint, glass, pearl et soapbubble sous `artifacts/webgpu-render-pathtracer/baselines/`.
- [ ] T006 Valider la reproductibilite des baselines par une seconde capture et publier `artifacts/webgpu-render-pathtracer/webgl-baseline-report.json`.

**Gate**: les contrats WebGL pathtracer et rasterizer et les baselines sont reproductibles; aucune modification des references n'est requise par la suite.

**Checkpoint**: Les contrats et les captures WebGL sont stables; `glsl/pathtracing/mtlx/` et `glsl/rasterization/mtlx/` n'ont pas ete modifies pour preparer le port.

---

## Phase 2 - Host generators pathtracer et rasterizer GLSL Vulkan

**Depends on**: T001-T006

- [ ] T007 Dans `../MaterialX-rva`, ajouter les tests de non-regression prouvant que `MtlxPathTracerHostShaderGenerator` conserve le GLSL WebGL actuel et que le rasterizer WebGL continue de fonctionner avec `EsslHostShaderGenerator`.
- [ ] T008 Adapter `MtlxPathTracerHostWgslShaderGenerator` pour emettre un fragment pathtracer GLSL Vulkan complet avec `#version 450`, entry point `main`, locations, sets, bindings et layouts explicites.
- [ ] T009 Porter le host rasterizer MTLX, notamment les flux bases sur `EsslHostShaderGenerator`, vers un GLSL Vulkan strict et compilable pour la meme chaine `glslang -> SPIR-V -> Naga -> WGSL`.
- [ ] T010 Ajouter au host Vulkan les types et helpers requis afin que les fragments pathtracer et rasterizer compilent sans prelude WebGL implicite.
- [ ] T011 Definir une seule table de bindings source dans `public/mtlx/wgsl-host-contract.json` ou un contrat render dedie, puis la consommer pendant la generation sans renommage regex.
- [ ] T012 Assembler les fragments GLSL Vulkan complets, integrateur et dispatch MaterialX inclus, avec detection des declarations ou ressources dupliquees.
- [ ] T013 Compiler avec glslang chaque fixture cible et conserver sources/logs dans `artifacts/webgpu-render-pathtracer/glsl-vulkan/`.
- [ ] T014 Rebuilder et publier atomiquement `JsMaterialXGenShader.js/.wasm/.data` sous `public/mtlx/`, puis verifier les hashes et les exports Emscripten.

**Checkpoint**: Toutes les fixtures produisent des fragments GLSL Vulkan courants compilables par glslang; les routes WebGL restent identiques.

---

## Phase 3 - SPIR-V, Naga et stages WGSL

**Depends on**: T014

- [ ] T015 Etendre `tools/compile-glsl-to-spirv.mjs` avec un mode fragment render qui fixe le stage et l'entry point, rejette les sorties obsoletes et ecrit un manifeste de hash.
- [ ] T016 Etendre `tools/transpile-glsl-to-wgsl.mjs` pour convertir le SPIR-V fragment avec la version Naga verrouillee et conserver les diagnostics complets.
- [ ] T017 Creer dans `src/webgpu/` un vertex WGSL minimal de fullscreen triangle qui produit la position clip et les coordonnees exigees par le fragment pathtracer et le fragment rasterizer.
- [ ] T018 [P] Ajouter un validateur vertex/fragment pour entry points, builtins, locations, groupes/bindings, uniform layouts, texture sample types et limites du device.
- [ ] T019 Executer la chaine `GLSL Vulkan -> glslang -> SPIR-V -> Naga -> WGSL` sur toute la matrice et publier `artifacts/webgpu-render-pathtracer/transpilation-report.json` avec hashes GLSL/SPIR-V/WGSL.

**Checkpoint**: Chaque fixture dispose de stages vertex et fragment WGSL valides, traçables jusqu'au GLSL courant.

---

## Phase 4 - Assemblage WGSL render

**Depends on**: T017-T019

- [ ] T020 Creer `src/webgpu/renderWgslModuleAssembler.js` pour assembler le fragment transpile avec les adaptations host requises, sans reutiliser l'assembleur compute comme autorite implicite.
- [ ] T021 Detecter dans l'assembleur les collisions de declarations module, bindings dupliques, entry points absents et interfaces inter-stage incompatibles.
- [ ] T022 Produire un contrat final versionne listant entry points vertex/fragment, bind group layouts et ressources attendues sous `public/mtlx/`.
- [ ] T023 Ajouter un test d'assemblage pour chaque fixture et verifier les modules finaux avec `GPUDevice.createShaderModule` dans un navigateur WebGPU reel.

**Checkpoint**: Tous les modules finaux compilent sans diagnostic GPU et exposent le meme contrat de ressources.

---

## Phase 5 - GPURenderPipeline et accumulation

**Depends on**: T023

- [ ] T024 Implementer dans `src/webgpu/` un renderer plein ecran qui cree un vrai `GPURenderPipeline` avec les stages vertex/fragment assembles et des color targets explicites.
- [ ] T025 Creer les bind groups pour camera, frame, BVH, geometrie, environnement, lumiere et ressources MaterialX; refuser toute ressource absente ou layout incompatible.
- [ ] T026 Implementer l'accumulation progressive avec textures ping-pong et render passes valides, sans lecture/ecriture simultanee interdite d'un attachement.
- [ ] T027 Integrer dans `main.js` une route explicite `webgpu_pipeline=render` conservant `webgpu_pipeline=compute` et `renderer_backend=webgl` inchanges.
- [ ] T028 Relier resize, reset camera, changement de scene/materiau, pause/reprise, compteur de samples et destruction/recreation des ressources.
- [ ] T029 Exposer dans le diagnostic runtime le type `render`, les hashes vertex/fragment, le statut pipeline/bind groups, les timings, samples, erreurs GPU et toute raison de fallback.
- [ ] T030 Ajouter une validation navigateur qui exige `GPURenderPipeline` actif, image non vide, objet visible, plusieurs samples, `gpuError=null` et aucun fallback compute/WebGL/legacy.

**Checkpoint**: Le navigateur rend et accumule avec un `GPURenderPipeline`; les diagnostics prouvent que l'image ne vient ni du compute ni de WebGL.

---

## Phase 6 - Comparaison visuelle et decision

**Depends on**: T030

- [ ] T031 Capturer les references WebGL `Pathtracer MTLX` et `Rasterizer MTLX` ainsi que le WebGPU render en verrouillant scene, camera, materiau, environnement, seed, bounces, samples, resolution et tonemapping.
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
