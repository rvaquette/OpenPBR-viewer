# Plan - Pathtracer MTLX WebGPU via GPURenderPipeline

Date: 2026-09-16

## Objectif

Porter la route plein ecran `Pathtracer MTLX` WebGL vers un vrai `GPURenderPipeline` WebGPU, sans remplacer ni modifier sa reference WebGL. Le shader MaterialX reste genere en GLSL par le host generator pathtracer, puis passe exclusivement par la chaine outillee `glslang -> SPIR-V -> Naga -> WGSL`.

Ce chantier est distinct du pathtracer compute de la spec 005. Il evalue une seconde architecture WebGPU qui reproduit le modele d'execution fragment du pathtracer WebGL existant. La comparaison finale determine si cette route render peut etre publiee, conservee comme voie experimentale ou abandonnee au profit du compute.

## Dependances sur la spec 005

La spec 006 ne rejoue pas la migration WebGPU generale. Elle reutilise les acquis valides de [la spec 005](../005-webgpu-migration/plan.md):

- selection explicite `renderer_backend` et cycle de vie du `GPUDevice`;
- contrat de scene, camera, geometrie, BVH, lumiere et textures;
- `MtlxPathTracerHostWgslShaderGenerator` et bindings Emscripten;
- compilation GLSL Vulkan par glslang, SPIR-V intermediaire et transpilation Naga;
- validation de source WGSL, contrats de bindings et diagnostics navigateur;
- baselines et metriques de comparaison du `Pathtracer MTLX` WebGL;
- contrat de generation et/ou de reference du rasterizer MTLX WebGL, notamment le host `EsslHostShaderGenerator` et le jeu de shaders `glsl/rasterization/mtlx/`.

Le chantier peut commencer quand la generation/transpilation MaterialX de la spec 005 est validee. Il n'attend pas les travaux de haze ou retroreflectivite qui ne touchent pas son contrat minimal, mais il inclut le portage parallele du rasterizer MTLX pour comparer la route render WebGPU aux deux references WebGL existantes.

## Decisions d'architecture

| Sujet | Decision |
|---|---|
| Reference | `glsl/pathtracing/mtlx/` et `glsl/rasterization/mtlx/`, ainsi que leurs host generators WebGL et captures associees, restent l'autorite fonctionnelle et visuelle. Ils ne sont ni remplaces ni reecrits pour WebGPU. |
| Nature du pipeline | Employer un `GPURenderPipeline` plein ecran. Un vertex shader WGSL minimal genere un fullscreen triangle; le fragment shader execute le pathtracer porte depuis la route WebGL. Ce pipeline est distinct du `GPUComputePipeline` de la spec 005. |
| Generation MaterialX | Adapter `MtlxPathTracerHostWgslShaderGenerator` et le host rasterizer MTLX/`EsslHostShaderGenerator` pour produire des fragments GLSL Vulkan complets, stricts et compilables. Malgre leur nom historique, ils n'emettent pas directement de WGSL. |
| Transpilation | Compiler le GLSL avec glslang vers SPIR-V, puis transpiler avec Naga vers WGSL. Aucune traduction ou correction semantique par regex JavaScript n'est acceptee. |
| Assemblage | Assembler un module vertex WGSL de fullscreen triangle et un module fragment WGSL contenant l'integrateur pathtracer, les helpers host et le dispatch MaterialX transpile. Valider interfaces, declarations et bindings avant creation du pipeline. |
| Accumulation | Preserver la semantique WebGL de rendu plein ecran et d'accumulation progressive. Utiliser des textures ping-pong ou un passage de composition explicite si WebGPU interdit une lecture/ecriture equivalente dans le meme render pass. |
| Parite | Comparer WebGPU render et WebGL a scene, camera, materiau, environnement, seed, rebonds, samples, resolution et tonemapping identiques. Aucun fallback compute, legacy ou WebGL masque n'est admis. |
| Decision produit | Le resultat est mesure face au pathtracer compute existant, mais la gate fonctionnelle est la parite avec le pathtracer WebGL de reference. |

## Hors portee

- Remplacement du pathtracer compute WebGPU deja implemente.
- Emission WGSL directe depuis MaterialX.
- Reimplementation independante des closures MaterialX ou du modele OpenPBR.
- Changement des equations, de la strategie d'echantillonnage ou du rendu WebGL pour faciliter le port.

Le portage du rasterizer MTLX est bien dans le scope du chantier, en parallele au port pathtracer, car il sert de deuxieme reference WebGL a comparer aux versions WebGPU render.

## Phase 1 - Figer la reference WebGL et le contrat fragment

1. Inventorier `glsl/pathtracing/mtlx/common.glsl`, `pathtracer.glsl`, le vertex fullscreen actuel, l'assemblage runtime et les fonctions generees par le host MaterialX.
2. Documenter les entrees du fragment pathtracer: camera, BVH, attributs, textures, environnement, lumiere, materiau, seed, samples et accumulation.
3. Capturer des baselines WebGL reproductibles pour les fixtures synthetiques et les materiaux `open_pbr_surface`, metal, carpaint, glass, pearl et soapbubble.
4. Versionner les metriques et seuils avant implementation: hash de dispatch, couverture objet, luminance, erreur RGB moyenne, pixels hors seuil et convergence par sample.

**Gate:** le contrat pathtracer WebGL et les baselines sont reproductibles; aucune modification de la reference n'est requise par la suite.

## Phase 2 - Host generators pathtracer et rasterizer GLSL Vulkan

1. Conserver les host generators WebGL actuels intacts.
2. Adapter `MtlxPathTracerHostWgslShaderGenerator` dans `MaterialX-rva` pour emettre le fragment host pathtracer en GLSL Vulkan strict: `#version 450`, entry point `main`, locations, sets, bindings et layouts explicites.
3. Porter le host rasterizer MTLX, notamment les flux bases sur `EsslHostShaderGenerator`, vers un GLSL Vulkan strict et compilable pour la meme chaine `glslang -> SPIR-V -> Naga -> WGSL`.
4. Fournir les helpers et types requis par les dispatch MaterialX sans dependance implicite a un prelude WebGL injecte hors du generateur.
5. Assembler cote GLSL les fragments pathtracer et rasterizer complets avec une seule autorite pour chaque declaration et chaque ressource.
6. Ajouter des tests qui compilent chaque fixture avec glslang et conservent le GLSL et les diagnostics en cas d'echec.

**Gate:** toutes les fixtures cible produisent des fragments GLSL Vulkan compilables par glslang, sans regex de reecriture et sans modifier leurs dispatch WebGL de reference.

## Phase 3 - GLSL vers SPIR-V vers WGSL

1. Etendre les outils de la spec 005 avec un mode `fragment-render` qui compile le GLSL Vulkan via glslang et conserve le SPIR-V intermediaire.
2. Transpiler ce SPIR-V avec Naga vers un module fragment WGSL, en fixant les versions et options des outils dans le rapport.
3. Generer ou maintenir separement le vertex WGSL minimal de fullscreen triangle avec l'UV et les donnees d'interpolation requises par le fragment.
4. Valider les deux stages: entry points, builtins, locations, groupes/bindings, uniform layouts, texture sample types et limites du device.
5. Rejeter les sorties obsoletes: chaque succes doit prouver que GLSL, SPIR-V et WGSL proviennent de la meme invocation et du meme hash source.

**Gate:** chaque fixture produit des artefacts vertex/fragment WGSL valides, lies au GLSL et au SPIR-V courants par un manifeste de hashes.

## Phase 4 - Assemblage vertex/fragment WGSL

1. Creer un assembleur render dedie, distinct de l'assembleur compute, qui combine le fragment transpile avec les adaptations host WGSL strictement necessaires.
2. Normaliser les noms d'entry points au niveau des outils de compilation, pas par traduction textuelle des corps de fonctions.
3. Detecter avant compilation les collisions de declarations module, les locations inter-stage incompatibles et les bindings dupliques.
4. Produire un contrat versionne du module final contenant les entry points vertex/fragment, bind group layouts et ressources attendues.
5. Tester l'assemblage sur toute la matrice de fixtures MaterialX avant integration navigateur.

**Gate:** les modules finaux sont acceptes par `GPUDevice.createShaderModule`, sans diagnostic de compilation et avec un contrat de ressources complet.

## Phase 5 - GPURenderPipeline et integration

1. Creer un `GPURenderPipeline` plein ecran utilisant le vertex WGSL et le fragment WGSL assembles, avec le format canvas, les color targets et les etats primitive/multisample explicites.
2. Creer les bind groups conformes au contrat: camera, frame, BVH, geometrie, environnement, lumiere et ressources MaterialX.
3. Implementer l'accumulation progressive sans feedback interdit entre attachement et texture echantillonnee; conserver reset, resize, pause/reprise et compteur de samples.
4. Ajouter une route explicite, par exemple `webgpu_pipeline=render`, sans changer la route compute par defaut et sans fallback silencieux.
5. Exposer les diagnostics: type reel du pipeline, hashes des stages, statut des bind groups, temps de compilation, samples, erreurs GPU et raison de fallback eventuelle.

**Gate:** un vrai `GPURenderPipeline` actif rend l'objet et accumule plusieurs samples dans Chrome WebGPU; les diagnostics prouvent que ni le compute shader ni WebGL ne produisent l'image.

## Phase 6 - Comparaison visuelle et decision

1. Capturer les references WebGL `Pathtracer MTLX` et `Rasterizer MTLX`, puis le WebGPU render avec les memes scene, camera, materiau, environnement, seed, rebonds, samples, resolution et tonemapping.
2. Comparer les images avec les metriques figees en Phase 1 et produire des diffs visuels inspectables.
3. Executer la matrice synthetique puis carpaint/transmission/thin-film, un navigateur/device isole par fixture si les compilations longues rendent une session partagee instable.
4. Tester changements de scene, materiau, resize et recreation de pipeline pour detecter erreurs GPU, ressources detruites ou accumulation non reinitialisee.
5. Produire un rapport go/no-go comparant parite, temps de compilation, temps par frame et convergence aux routes WebGL de reference (pathtracer + rasterizer) et WebGPU compute existante.

**Gate finale:** toutes les fixtures obligatoires utilisent le `GPURenderPipeline`, n'ont aucune erreur GPU ni fallback masque et respectent les seuils visuels WebGL pour les deux references `Pathtracer MTLX` et `Rasterizer MTLX`. Toute divergence acceptee est documentee fixture par fixture.

## Risques et parades

| Risque | Parade |
|---|---|
| Le fragment pathtracer depasse les limites d'un render pipeline ou compile tres lentement | Mesurer par fixture, compiler de facon asynchrone, mettre en cache par hash et garder la route compute comme solution de production tant que la gate n'est pas atteinte. |
| Le GLSL WebGL depend de comportements non representables en Vulkan GLSL | Corriger l'adaptation dans le host Vulkan uniquement; ne pas alterer la reference WebGL et ne pas ajouter de regex au viewer. |
| Naga renomme ou reorganise les interfaces | Valider le module transpile par reflection/contrat, puis utiliser les noms et bindings produits plutot que des suppositions textuelles. |
| Feedback d'accumulation interdit dans un render pass | Employer deux textures alternantes et des render passes separes, avec reset explicite. |
| Comparaison stochastique instable | Fixer seed et sample count, comparer aussi luminance/convergence et utiliser des seuils statistiques documentes. |

## Ordre recommande

1. Reference et contrat WebGL.
2. Fragment host GLSL Vulkan compilable.
3. Transpilation glslang/SPIR-V/Naga et vertex WGSL.
4. Assemblage des stages et validation des bindings.
5. `GPURenderPipeline` et accumulation navigateur.
6. Comparaison visuelle et decision go/no-go.

Ce plan est volontairement autonome et court: il reutilise l'infrastructure de la spec 005 mais possede sa propre gate, ses artefacts et sa liste de taches.
