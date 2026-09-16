# Plan de migration WebGPU

Date: 2026-09-11

## Objectif

Ajouter un moteur WebGPU de production au viewer sans modifier les flux utilisateur existants: chargement de scene GLB, selection MaterialX, controles de camera et parametres OpenPBR. Le moteur WebGL2 actuel reste disponible pendant toute la migration comme reference visuelle et repli de compatibilite.

La premiere cible WebGPU est le **Pathtracer MTLX**, car il concentre le pipeline le plus contraint (BVH, accumulation, textures, eclairage et dispatch MaterialX). Le rasterizer WebGPU ne sera entrepris qu'apres parite fonctionnelle et visuelle de cette route.

## Decisions d'architecture

| Sujet | Decision |
|---|---|
| API de rendu | Employer l'API WebGPU native pour le path tracer (`navigator.gpu`, `GPUDevice`, compute pipeline), pas `WebGPURenderer` de three.js. |
| Three.js | Conserver Three.js pour GLTFLoader, BufferGeometry, camera, OrbitControls et la scene de previsualisation WebGL. Il ne possede pas les pipelines WebGPU du path tracer. |
| Execution | Un shader compute WGSL trace un pixel par invocation et ecrit dans une texture HDR d'accumulation. Un passage de presentation applique moyenne et tonemapping vers le canvas. |
| Geometrie | Remplacer les textures GLSL du BVH et des attributs par des `GPUBuffer` de stockage. Conserver le format BVH natif tant qu'un layout binaire explicite est documente et teste. |
| Materiaux | Le WASM MaterialX continue de generer du GLSL via `WgslShaderGenerator`/`MtlxPathTracerHostWgslShaderGenerator`, sans emission WGSL directe. Une etape de transpilation dediee convertit ce GLSL en WGSL via un passage intermediaire SPIR-V (`glslang` puis `naga`/`Tint`) quand une conversion textuelle directe n'est pas fiable. Aucune regex ad hoc sur le GLSL genere n'est acceptee comme substitut a ce pipeline outille. |
| Rasterizer WebGPU | Conserver `glsl/rasterization/mtlx/` et son GLSL MaterialX genere comme autorite fonctionnelle WebGL. Le port WebGPU adapte ce host raster vers un GLSL Vulkan vertex/fragment, le transpile avec la meme chaine `glslang -> SPIR-V -> Naga/Tint -> WGSL`, puis l'assemble dans un `GPURenderPipeline` natif distinct du compute path tracer. |
| Compatibilite | Choisir WebGPU quand disponible et demande par l'utilisateur; conserver WebGL2 sinon. Aucun repli silencieux MaterialX vers les BRDF legacy. |
| Comparaison | Les captures WebGL2 existantes constituent le baseline. Les comparaisons WebGPU sont faites a scene, camera, seed, taille, nombre de rebonds et nombre de samples identiques. |

## Etat de depart

- [main.js](../../main.js) centralise les quatre modes: rasterizer/pathtracer et MTLX/legacy.
- La route `Pathtracer MTLX` est un plein ecran WebGL avec accumulation alpha dans un `WebGLRenderTarget` flottant.
- Le BVH de la route MTLX est deja un format local (`src/bvh/`) expose a GLSL par textures; les attributs sont empaquetes dans `geomN`, `geomT` et `geomS`.
- [glsl/pathtracing/mtlx/pathtracer.glsl](../../glsl/pathtracing/mtlx/pathtracer.glsl) porte `trace`, les lumières, le sol et l'integrateur; le dispatch MaterialX est injecte a l'execution.
- Le dispatch MTLX genere doit fournir `mtlxGenEvaluateBsdf` et `mtlxGenSampleBsdf`; son absence est une erreur explicite, sans fallback legacy.
- Le bundle WASM publie sous `public/mtlx/` est actuellement issu de `PathTracerGlslShaderGenerator.cpp`. Il doit etre etendu pour embarquer les bindings de `JsWgslShaderGenerator.cpp`, qui continue de produire du GLSL Vulkan valide; ce changement est un prerequis de la route MaterialX WebGPU.
- La route WebGPU ne consomme jamais ce GLSL directement: un pipeline de transpilation `tools/` compile le GLSL en SPIR-V puis en WGSL avant tout usage par l'integrateur WebGPU.
- [launch_render.mjs](../../launch_render.mjs) fournit la capture de reference WebGL. Les validations WebGL deterministes utilisent `--gpu=false`.

## Phase 0 - Cadrage et baseline

1. Ajouter une capacite `renderer_backend` avec `webgl` par defaut et `webgpu` comme option explicite. La selection doit etre visible dans l'URL et dans le rapport de diagnostic JavaScript.
2. Definir les navigateurs et GPU supportes: Chrome/Edge WebGPU stables en premier; indiquer clairement le repli WebGL2 pour les contextes sans `navigator.gpu` ou sans adaptateur utilisable.
3. Capturer le baseline WebGL2 pour `standard-shader-ball`, `glavenus`, `terrain` et `bearded-man`, en `Pathtracer MTLX`, avec les materiaux library representatifs: opaque, metal, verre, texture procedurale et emissif.
4. Produire un manifeste par capture: scene, materiau, URL complete, resolution, samples, bounces, seed, version du dispatch MTLX et hash de l'image.
5. Ecrire les tolerances de comparaison avant implementation: erreur RGB moyenne, seuil de pixels ecrases, et exceptions identifiees pour les differences de precision et de denoising.

**Gate:** le baseline est reproductible et les quatre captures WebGL2 existantes restent vertes avec `npm run build`.

## Phase 1 - Hote WebGPU minimal

1. Creer `src/webgpu/` avec un `WebGpuRenderer` responsable de l'adaptateur, du device, du canvas context, du redimensionnement, des erreurs `device.lost` et de la liberation des ressources.
2. Extraire de `main.js` un contrat de scene independant du backend: camera, dimensions, parametres de rendu, lumières, textures, buffers de geometrie et etat d'accumulation.
3. Implementer un pipeline WGSL de fumee qui remplit le canvas avec une couleur et encode un compteur de frame. Verifier la negociation du format canvas avec `navigator.gpu.getPreferredCanvasFormat()`.
4. Ajouter la presentation HTML des erreurs WebGPU: absence de WebGPU, refus d'adaptateur, erreur de validation WGSL et perte de device. Ne jamais basculer silencieusement vers WebGL apres une erreur de pipeline.
5. Integrer l'initialisation WebGPU au cycle `load_scene`, `resize`, `resetSamples` et `render`, sans changer les controles GUI existants.

**Gate:** `?renderer_backend=webgpu` initialise un canvas WebGPU, redimensionne correctement et `npm run build` passe. `?renderer_backend=webgl` conserve strictement le comportement actuel.

## Phase 2 - Donnees GPU et accumulation

1. Definir les layouts binaires avec alignement WGSL explicite: `CameraUniforms`, `RenderUniforms`, `Light`, `BvhNode`, `TriangleIndices` et attributs de sommet. Documenter taille, offsets et format de chaque champ dans un module commun JS/WGSL.
2. Convertir le BVH et la geometrie combines de `buildCombinedSurfaceGeometry()` en buffers de stockage: positions, indices, normales, tangentes, UV et `neutralFlag`.
3. Porter la traversee stack-based de `nativeBvhIntersectFirstHitWithinDistance` en WGSL. Ajouter un compteur de debordement de pile et une sortie de diagnostic plutot qu'un rendu corrompu silencieux.
4. Allouer deux textures `rgba16float` ou `rgba32float` pour ping-pong: une somme radiance et un compteur/poids. Le reset remplace les ressources ou les efface via compute, sans utiliser le blending WebGL.
5. Ajouter le compute de presentation: moyenne par nombre de samples, conversion lineaire vers l'espace de sortie et tonemapping actuellement applique par l'affichage WebGL.

**Gate:** scene geometrique neutre puis `standard-shader-ball` sont rendues sans MaterialX; intersections, normales, UV, sol et accumulation restent stables apres resize, pause, reprise et reset camera.

## Phase 3 - Integrateur WGSL de reference

1. Porter depuis `glsl/pathtracing/mtlx/common.glsl` les types et fonctions sans dependance MaterialX: RNG, Basis, transformations local/monde, Fresnel, GGX, echantillonnage hemispherique et MIS.
2. Porter `trace`, les BRDF Lambert des props et du sol, soleil analytique, envmap, lumières MTLX empaquetees et ombres depuis `pathtracer.glsl`.
3. Conserver les conventions existantes: sens des rayons, `pdf`, energie, `MATERIAL_PROPS`, `MATERIAL_OPENPBR`, `MATERIAL_GROUND`, espaces de couleur et UV du sol.
4. Ajouter des shaders de diagnostic selectionnables uniquement par URL: distance de hit, identifiant materiau, normale, UV, PDF et nombre de rebonds. Ils remplacent les inspections GLSL possibles aujourd'hui.
5. Valider separement une scene Lambert, la reflexion speculaire, le metal, le sol texture, une lumiere ponctuelle/directionnelle/spot/quad et l'envmap avant la couche MaterialX.

**Gate:** le path tracer WGSL rend correctement une scene sans dispatch MaterialX et respecte les invariants des diagnostics. Les resultats convergent vers le baseline WebGL dans les tolerances documentees.

## Phase 4 - MaterialX vers GLSL, puis transpilation SPIR-V vers WGSL

1. Dans `MaterialX-rva`, integrer `JsWgslShaderGenerator.cpp` a la cible Emscripten qui produit le runtime consomme par le viewer. Exporter la fabrique JavaScript/WASM correspondante, ses classes `GenContext` et les types MaterialX requis, en plus du generateur GLSL actuel pendant la periode de migration.
2. Porter `MtlxPathTracerHostShaderGenerator` vers une variante `MtlxPathTracerHostWgslShaderGenerator` construite sur `WgslShaderGenerator`. Cette variante reste un generateur **GLSL Vulkan valide et complet** (types, qualifiers, `layout`/`binding`, `main()`); elle n'emet pas de WGSL. Elle est responsable du host path-tracing: normalisation des entrees MaterialX, adaptation des closures et emission des points d'entree `mtlxGenEvaluateBsdf`/`mtlxGenSampleBsdf` en GLSL, destines a la transpilation.
3. Conserver les deux host generators pendant la migration: `MtlxPathTracerHostShaderGenerator` reste l'autorite de la route WebGL GLSL directe (sans transpilation); `MtlxPathTracerHostWgslShaderGenerator` reste l'autorite du GLSL source de la route WebGPU, transpile ensuite vers WGSL. Aucun des deux ne doit emettre de WGSL directement.
4. Garantir que le GLSL emis par `MtlxPathTracerHostWgslShaderGenerator` est un GLSL Vulkan strict et compilable par `glslang`: `#version 450`, `layout(set=N, binding=M)` explicites pour chaque ressource, pas de qualifiers ou d'extensions incompatibles avec la cible SPIR-V utilisee par la transpilation.
5. Choisir et integrer l'outil de compilation GLSL vers SPIR-V (`glslang`, via binaire natif ou binding WASM) dans la chaine d'outillage `tools/`; documenter la version, les flags de cible (`--target-env vulkan1.x`) et le mode d'invocation reproductible en CI comme en local.
6. Choisir et integrer l'outil de transpilation SPIR-V vers WGSL (`naga` ou `Tint`) dans `tools/`; documenter la version, les flags utilises et les limitations connues du sous-ensemble SPIR-V accepte pour les shaders de calcul MaterialX.
7. Implementer `tools/transpile-glsl-to-wgsl.mjs`: GLSL genere -> SPIR-V (`glslang`) -> WGSL (`naga`/`Tint`), avec un mode diagnostic qui conserve les artefacts intermediaires (`.spv`, log de validation) en cas d'echec pour faciliter le triage.
8. A la frontiere de transpilation, aligner les decorations Vulkan (`layout(set=, binding=)`, `std140`, `push_constant`) avec les groupes/bindings attendus par le contrat WebGPU (`FrameUniforms`, `CameraUniforms`, `Light`, `BvhNode`, `TriangleIndices`, accumulation, BVH, sol, lumiere, environnement), afin que le WGSL transpile respecte le layout sans renommage manuel cote JavaScript.
9. Valider l'API WASM publiee avec un programme minimal: charger les bibliotheques standard, lire un `.mtlx`, trouver l'element rendu, instancier le host generator GLSL destine a la transpilation et recuperer la source du stage approprie. Consigner le nom exact de la fabrique, du host generator et du stage dans le contrat, plutot que de le deviner dans le viewer.
10. Ajouter un contrat WGSL versionne, distinct de `generator-abi-expectations.json`: fonctions BSDF, structures partagees, ressources textures, groupe/binding, espaces de couleur et metadata du materiau. Le validateur controle le WGSL **transpile final**, pas le GLSL intermediaire.
11. Generer, transpiler puis valider les cinq fixtures synthetiques et les cinq fixtures carpaint existantes dans un runner T043. Chaque fixture doit produire un GLSL intermediaire, un SPIR-V valide, un fichier WGSL transpile, et passer le validateur de contrat sur ce WGSL final. Le rapport doit conserver les erreurs detaillees par fixture et par etape (generation GLSL, compilation SPIR-V, transpilation WGSL, validation contrat).
12. Publier ensemble les artefacts Emscripten mis a jour (`.js`, `.wasm`, `.data`), une nouvelle version de runtime, le registre de fonctions et la version figee du pipeline de transpilation (`glslang`/`naga`/`Tint`). Mettre a jour `public/mtlx/PUBLISH_INFO.md` pour referencer `JsWgslShaderGenerator.cpp`, le host generator GLSL et la chaine de transpilation, et empecher le melange cache d'une table d'offsets JavaScript et d'un payload WASM/Data incompatible.
13. Dans le viewer, separer `generateMtlxRouteDispatch()` en deux adaptateurs explicites: l'adaptateur WebGL continue d'appeler `MtlxPathTracerHostShaderGenerator` et consomme du GLSL directement; l'adaptateur WebGPU charge le meme runtime WASM, appelle `MtlxPathTracerHostWgslShaderGenerator` pour obtenir du GLSL, puis invoque le pipeline de transpilation avant de consommer le WGSL resultant. La selection depend de `renderer_backend`, jamais d'une conversion de texte ad hoc.
14. Remplacer `extractMtlxTextureBindings()` pour la route WebGPU par un manifeste de ressources genere: dimensions, espace de couleur, type echantillonnable, sampler et groupe/binding WebGPU, coherent avec les decorations Vulkan transpilees. Les textures restent individuelles au MVP afin de respecter les graphes MaterialX existants.
15. Construire le pipeline WGSL final par assemblage de modules WGSL transpiles valides, avec une verification de signatures, de collisions de noms et des limites `maxBindGroups`/`maxSampledTexturesPerShaderStage` avant `createShaderModule` et `createComputePipelineAsync`.
16. Implementer les erreurs explicites couvrant chaque etape: generation GLSL invalide, echec de compilation SPIR-V, echec de transpilation WGSL, closure non supportee, dispatch incomplet, texture absente, signature invalide ou nombre de bindings depassant les limites de l'adaptateur.

**Gate WASM:** le bundle publie expose simultanement le host generator GLSL existant, `JsWgslShaderGenerator.cpp`/`MtlxPathTracerHostWgslShaderGenerator` (GLSL) et le pipeline de transpilation `glslang`/`naga`/`Tint` fige en version; un fixture de chaque modele MVP produit un GLSL valide, un SPIR-V valide, puis un WGSL transpile qui respecte le contrat de fonctions et bindings.

**Gate rendu:** les cinq modeles et leurs fixtures synthetiques traversent generation GLSL, compilation SPIR-V et transpilation WGSL sans erreur, puis produisent un rendu WebGPU sans approximation legacy ni fallback masque.

## Phase 5 - Parite OpenPBR et fonctions avancees

1. Porter et comparer les proprietes v1.2: coat darkening, Fresnel F82 borne, clamping des entrees, specular weight/IOR, transmission scatter, thin-walled et subsurface.
2. Porter thin film spectral et dispersion en preservant la strategie de longueur d'onde hero existante; valider absence de double ponderation spectrale.
3. Porter haze dual-lobe et retroreflectivite seulement apres que la route WebGL de reference les expose integralement et que leur contrat de parametres est fixe.
4. Resoudre ou desactiver clairement le chemin CDF envmap actuellement connu comme surexpose avant de l'activer dans WebGPU. Ne pas propager un comportement non valide vers le nouveau backend.
5. Ajouter une table de parite par parametre et par modele MaterialX avec statut: non applicable, implemente, compare, accepte.

**Gate:** la matrice de parite est complete pour les fonctionnalites promises; aucune fonctionnalite marquee supportee ne depend d'un chemin GLSL legacy.

## Phase 6 - Rasterizer, experience et deploiement

### 6.1 - Autorite WebGL et inventaire raster

1. Conserver `glsl/rasterization/mtlx/` sans remplacement comme implementation de reference WebGL2 du rasterizer MTLX. Son vertex shader, son fragment host, ses conventions d'interpolation, d'eclairage, d'environnement, de profondeur, de blending et le GLSL produit par `EsslHostShaderGenerator` constituent le contrat comportemental a porter.
2. Inventorier les entrees/sorties vertex-fragment, uniforms, textures, samplers, light data, espaces de couleur, etats depth/cull/blend et points d'injection du GLSL MaterialX. Versionner ce contrat avant toute implementation WebGPU.
3. Capturer des baselines raster WebGL2 reproductibles pour les materiaux opaques, metal, transmission, thin-film et textures, avec scene, camera et environnement fixes.

### 6.2 - Host generator raster Vulkan et transpilation

1. Ajouter dans `MaterialX-rva` un host generator raster dedie a WebGPU qui adapte le comportement de `EsslHostShaderGenerator` et du host actuel, mais emet deux stages GLSL Vulkan stricts et compilables: vertex et fragment. Le generateur ne doit pas emettre directement du WGSL et ne doit pas modifier la route WebGL de reference.
2. Emettre des `layout(location=N)` coherents entre vertex outputs et fragment inputs, ainsi que des `layout(set=N,binding=M)`/`std140` explicites pour toutes les ressources raster. Les bindings doivent etre derives d'un contrat versionne, sans renommage regex JavaScript.
3. Etendre le pipeline outille existant pour compiler chaque stage avec `glslang`, conserver les SPIR-V intermediaires, puis transpiler vertex et fragment avec Naga/Tint. Les diagnostics doivent distinguer generation GLSL, compilation SPIR-V, transpilation WGSL et validation inter-stage.
4. Valider les modules WGSL vertex/fragment separement puis ensemble: signatures d'entry points, locations, builtins, bindings, collisions de declarations et compatibilite des ressources avec les limites du device.

### 6.3 - Pipeline render WebGPU natif

1. Assembler le WGSL host raster et le WGSL MaterialX transpile sans utiliser le compute path tracer ni un rendu a un sample comme substitut.
2. Creer un vrai `GPURenderPipeline` WebGPU avec vertex buffers, primitive state, depth/stencil, multisampling si retenu, culling et color targets correspondant au rasterizer WebGL de reference.
3. Uploader et binder matrices camera/objet, attributs geometriques, lumières, environnement et textures MaterialX suivant le contrat raster. Refuser explicitement toute ressource absente ou tout layout incompatible.
4. Integrer ce pipeline comme mode `Rasterizer MTLX` lorsque `renderer_backend=webgpu`, tout en conservant la route `Rasterizer MTLX` WebGL2 intacte et selectionnable comme reference.

### 6.4 - Parite, experience et deploiement

1. Comparer les captures du `GPURenderPipeline` WebGPU aux captures du rasterizer WebGL2 existant, a scene, camera, resolution, materiau et environnement identiques. Mesurer erreur RGB moyenne, pixels hors seuil, profondeur/alpha et differences de silhouettes; documenter toute divergence acceptee.
2. Ajouter le choix `WebGL2`/`WebGPU` dans le GUI avec etat indisponible explicite. Maintenir les modes legacy comme outils de comparaison tant qu'ils apportent de la valeur.
3. Instrumenter les timings: chargement scene, creation buffers, upload textures, creation module/pipeline et temps GPU par frame. Utiliser `GPUQuerySet` quand l'adaptateur le permet, avec fallback CPU clairement etiquete.
4. Etendre `launch_render.mjs` avec `--backend=webgpu`, attente du premier frame raster valide et export de diagnostics adaptateur/device. Les captures WebGPU necessitent un navigateur et un GPU compatibles; SwiftShader WebGL ne constitue pas une validation WebGPU.
5. Publier une matrice support navigateur/GPU et les limitations connues. Conserver la route WebGL2 par defaut jusqu'a validation multiplateforme.

**Gate:** le rasterizer WebGPU utilise un vrai `GPURenderPipeline` vertex/fragment issu du host raster Vulkan et de la chaine `glslang -> SPIR-V -> Naga/Tint -> WGSL`; les captures automatisees des scenes de reference respectent les seuils de comparaison avec `glsl/rasterization/mtlx`, sans fallback compute/legacy, sans fuite de ressources sur changements repetes de scene/materiau et avec un build Vite vert.

## Risques et parades

| Risque | Parade |
|---|---|
| Le sous-ensemble SPIR-V/GLSL genere par MaterialX n'est pas entierement supporte par `naga`/`Tint` | Fixer les versions de `glslang`/`naga`/`Tint`, conserver les artefacts `.spv` en cas d'echec, et limiter au depart les closures/materiaux aux constructions GLSL connues comme transpilables. |
| Decorations Vulkan (`layout(set=,binding=)`, `std140`) mal mappees vers les groupes/bindings WebGPU attendus | Aligner explicitement les decorations emises par `MtlxPathTracerHostWgslShaderGenerator` avec le contrat WebGPU avant transpilation; valider le WGSL transpile final contre ce contrat, pas contre le GLSL intermediaire. |
| Limites de bindings pour graphes MaterialX textures | Manifeste de bindings, validation precoce contre les limites du device; atlas seulement apres une conception MaterialX dediee. |
| Divergence WebGL/WebGPU par precision et RNG | Seed/echantillonnage documentes, tests par invariants et seuils visuels plutot qu'egalite pixel exacte. |
| Gros shaders MaterialX lents a compiler | Cache par hash de materiau et pipeline async; afficher la progression et diagnostiquer les erreurs WGSL. |
| Support WebGPU incomplet | Detection avant chargement, WebGL2 conserve comme repli explicite. |
| Modifications simultanees du renderer actuel | Isoler `src/webgpu/` et le contrat de scene; garder les changements de `main.js` minimaux et reversibles. |

## Ordre recommande

1. Phase 0: baseline et contrats.
2. Phase 1: hote WebGPU minimal.
3. Phase 2: buffers, BVH et accumulation.
4. Phase 3: integrateur independant de MaterialX.
5. Phase 4: generation MaterialX GLSL puis transpilation SPIR-V vers WGSL, le risque principal.
6. Phase 5: parite OpenPBR avancee.
7. Phase 6: rasterizer, automatisation et publication.

Le passage a WebGPU ne doit etre considere comme termine qu'apres validation du pipeline GLSL -> SPIR-V -> WGSL et comparaison sur les scenes reelles. Un simple port du canvas ou un rendu raster WebGPU ne valide pas le coeur fonctionnel du viewer.