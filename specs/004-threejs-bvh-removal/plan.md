# Plan — Retrait de three.js/three-mesh-bvh côté GLSL, remplacement par le code de GLSL-PathTracer-JS

Date: 2026-09-08

## Constat clé (avant planification)
Seul le **BVH** dépend réellement de three.js côté GLSL (`shaderStructs`, `shaderIntersectFunction`,
`uniform BVH`, `MeshBVHUniformStruct`, `FloatVertexAttributeTexture`, `StaticGeometryGenerator`, `SAH`,
`MeshBVH`). L'envmap et les textures matériaux sont déjà de simples `sampler2D` — seul leur *chargement*
passe par `TextureLoader`/`RGBELoader` de three.js. Le rendu (boucle `render()`, accumulation,
`FullScreenQuad`) reste tel quel : on réutilise le pathtracer MTLX local (`main.js` +
`glsl/pathtracing/mtlx/*`), adapté aux besoins du chantier — pas le moteur de rendu de
GLSL-PathTracer-JS (pas de FBO/tuiles/skeleton.glsl).

## Portée retenue
1. **BVH (obligatoire)** : remplacer `three-mesh-bvh` par le code JS + GLSL porté de `GLSL-PathTracer-JS`.
2. **Envmap (chargement + upload)** : remplacer `RGBELoader`/mipmaps auto three.js par un loader HDR
   natif + upload manuel. CDF importance sampling = option à confirmer séparément.
3. **Textures matériaux/sol** : remplacer `TextureLoader` par un chargeur natif (Image/ImageBitmap),
   toujours en `sampler2D` individuels (pas de texture-array : le dispatch WASM attend des noms de
   samplers fixes par matériau).
4. **Matériaux** : inchangé — génération WASM MaterialX conservée intégralement
   (`generateMtlxRouteDispatch`, `configureSingleMtlxMaterial`, `assemble_mtlx_route_dispatch`,
   `emitMtlxMaterialValueFunction`, bridge `mtlx_openpbr_*`).
5. **Boucle de rendu** : inchangée — on garde `main.js` (`render()`, `trigger_recompile`,
   `FullScreenQuad`, accumulation `samples`/`accumulation_weight`).

## Phase 1 — BVH : port JS (construction + upload GPU)

> ✅ **Statut : VALIDÉE.** Rendu confirmé correct (`Rasterizer legacy`, `Rasterizer MTLX`,
> `Pathtracer MTLX`, `Pathtracer legacy`). Un paramètre `bvh_engine` (`threejs` par défaut, `native`
> en option) permet de choisir entre `three-mesh-bvh` et le port local `src/bvh/*` ; les deux passent
> par le même point d'appel GLSL (`bvhIntersectFirstHitWithinDistance`). Bug corrigé côté GLSL natif :
> la taille de feuille (`metadata.y`) était ignorée (boucle figée à 1 triangle) dans
> `src/bvh/shader.js`.

Nouveaux fichiers (`src/bvh/` ou équivalent) :
- `bvh.js` — port de `bvh.ts` (SAH top-down) en JS pur, à partir de positions/indices bruts extraits
  des `BufferGeometry` déjà chargées par `GLTFLoader` (conservé, seul le calcul BVH change).
- `bvhTranslator.js` — port de `bvhTranslator.ts`, aplatit l'arbre en tableau `NodeBvh`
  (bboxmin/bboxmax/LRLeaf). BLAS/TLAS à évaluer (une seule géométrie combinée neutre+openpbr ici →
  un seul niveau peut suffire).
- `bbox.js` — port de `bbox.ts`.

Modifications `main.js` :
- Retirer les imports `MeshBVH, MeshBVHUniformStruct, FloatVertexAttributeTexture, shaderStructs,
  shaderIntersectFunction, SAH, StaticGeometryGenerator` de `three-mesh-bvh`.
- `MeshLoader.load()` : garder `GLTFLoader`, remplacer `StaticGeometryGenerator` + `new MeshBVH(...)`
  par extraction de triangles bruts → `new Bvh(...)`/`BvhTranslator`.
- `buildCombinedSurfaceGeometry()` / `packSurfaceGeom()` : adapter au nouveau format GPU
  (positions/normales/tangentes/uv/neutralFlag).
- Remplacer `bvh_surface: { value: new MeshBVHUniformStruct() }` par des uniforms texture RGB32F
  (nœuds BVH) + textures verticesTex/normalsTex/vertexIndicesTex (ou garder le format geomN/geomT/geomS
  actuel si plus proche du besoin — à trancher en Phase 1).
- Supprimer `makeBvhPortable()`/`bvhPortableHook` (hack devenu inutile).

Modifications GLSL (`glsl/pathtracing/mtlx/common.glsl`, `pathtracer.glsl`, et équivalents
`glsl/rasterization/mtlx/*`) :
- Remplacer `uniform BVH bvh_surface;` et le code injecté par three-mesh-bvh par les déclarations et
  fonctions portées de `shaders/common/intersection.glsl`, `anyhit.glsl`, `closest_hit.glsl` de
  GLSL-PathTracer-JS (adaptées aux noms/uniforms locaux, `MATERIAL_PROPS/MATERIAL_OPENPBR/MATERIAL_GROUND`
  conservés).
- `trace()` garde sa signature actuelle ; seule la traversée BVH interne change (Möller–Trumbore +
  stack-based, remplace `intersectTriangles`/`intersectsBVHNodeBounds`/`uTexelFetch1D`/
  `textureSampleBarycoord`).

Validation : `npm run build`, rendu visuel `standard-shader-ball` en `Pathtracer MTLX` et
`Rasterizer MTLX`, comparaison avant/après.

Test de rendu de validation de phase :
- Scène cible : `standard-shader-ball`
- Mode : `Pathtracer MTLX`
- Vérification : la scène charge sans crash, le BVH traverse correctement, les ombres et les reflets
  restent stables, et la sortie visuelle reste cohérente sur 20 à 50 échantillons.
- **Tous les tests de rendu (`launch_render.mjs`) doivent être exécutés avec `--gpu=false`**
  (rendu logiciel SwiftShader), afin d'obtenir un rendu déterministe et reproductible en headless.

## Phase 2 — Envmap : chargement natif + upload GPU

> ✅ **Statut : VALIDÉE.** Loader RGBE (.hdr) natif dans `src/envmap/hdrLoader.js` (parse header +
> scanlines RLE/flat, conversion half-float) et chargeur LDR natif (`createImageBitmap`, sans
> `THREE.TextureLoader`) dans `src/envmap/envLoader.js`. Upload GPU via `THREE.DataTexture`/
> `THREE.Texture` (classes core three.js, pas des addons) plutôt que `gl.texImage2D` manuel — plus
> sûr et évite de contourner la gestion de texture de `WebGLRenderer`. CDF importance sampling non
> inclus (reporté, comme prévu).

- Nouveau loader HDR JS pur (port simplifié de `HDRLoader`/`EnvironmentMap`), sans `RGBELoader` three.js.
- Textures `.jpg`/`.png` existantes : décodeur léger (canvas 2D/`createImageBitmap`) sans
  `THREE.TextureLoader`.
- Upload GPU manuel via `gl.texImage2D` sur le contexte WebGL2 de `renderer.getContext()` (three.js
  `WebGLRenderer` reste le conteneur de contexte, mais l'objet texture n'est plus un `THREE.Texture`).
- Optionnel (à confirmer) : CDF luminance + `SampleEnvMap()`/`EvalEnvMap()` portés de
  `shaders/common/envmap.glsl` — change le comportement MIS actuel (`skyPdf`/`sunPdf`), à valider
  séparément avant inclusion.

Test de rendu de validation de phase :
- Scène cible : `glavenus`
- Mode : `Pathtracer MTLX`
- Vérification : l'envmap charge correctement, la lumière du ciel est stable, les reflets sur les
  surfaces métalliques restent cohérents et aucun artefact de gradient ou de branchement lat-long ne
  apparaît.

## Phase 3 — Textures matériaux/sol : chargement natif
- Remplacer `new TextureLoader().load(url)` (sol + `createMtlxRouteTextureUniforms`) par un chargeur
  natif `Image`/`createImageBitmap` + upload manuel `gl.texImage2D`.
- Garder un sampler nommé par fichier texture (pas de texture-array), pour rester compatible avec les
  noms générés par le dispatch WASM (`${parentName}_file`).

Test de rendu de validation de phase :
- Scène cible : `terrain`
- Mode : `Rasterizer MTLX` puis `Pathtracer MTLX`
- Vérification : les textures de sol et de matériau se chargent correctement, les UVs restent cohérents,
  et aucune écriture en noir/bleu/blanc ne masque le détail des textures ni les transitions de matériau.

## Phase 4 — Nettoyage et dépendances

> ⚠️ **Écart assumé vs plan initial** : `three-mesh-bvh` n'est **pas** retiré de `package.json`. Suite
> à la Phase 1, `params.bvh_engine` a été introduit avec `'threejs'` (three-mesh-bvh, via
> `src/bvh-compat.js`) comme moteur **par défaut**, `'native'` (`src/bvh/*`) restant une option. La
> dépendance est donc désormais délibérément conservée, pas un reliquat oublié.

- ~~Retirer `three-mesh-bvh` de `package.json`~~ — conservé intentionnellement (voir ci-dessus).
- Retirer `RGBELoader`/`TextureLoader` de `main.js` si totalement remplacés (vérifier usages legacy
  avant suppression). ✅ Fait (Phases 2/3) : plus aucun import de ces classes dans `main.js`, seuls des
  commentaires les mentionnent encore par nom.
- Revalidation complète : `npm run build`, `node launch_render.mjs` sur les 4 modes de rendu et les
  scènes `standard-shader-ball`, `glavenus`, `terrain`, `bearded-man`.

Test de rendu final de phase :
- Scène cible : `bearded-man`
- Modes : `Pathtracer MTLX`, `Rasterizer MTLX`, `Pathtracer legacy`, `Rasterizer legacy`
- Vérification : le rendu final est stable sans dépendance three.js côté GLSL, sans crash de BVH, sans
  rupture sur l'envmap et sans cassure sur les textures de matériau. On garde le comportement visuel
  principal sur la scène la plus complexe du projet.

> ✅ **Statut : VALIDÉE** (2026-09-08). `npm run build` propre et les 4 modes rendus sur `bearded-man`
> avec `--gpu=false`, sans crash ni BVH figé (moteur par défaut `threejs`, ~2.4M triangles). Aucune
> texture noire/cassée observée. `RGBELoader`/`TextureLoader` confirmés absents de `main.js`.

## Note transversale — mode de test GPU
Tous les tests de rendu de validation de phase (toutes phases confondues, Phase 1 à Phase 4) doivent
être lancés avec l'option `--gpu=false` de `launch_render.mjs` (rendu logiciel SwiftShader). Ne pas
valider de rendu en mode GPU matériel (`--gpu=true`/défaut), qui peut masquer des divergences ou au
contraire faire échouer un rendu qui fonctionne correctement en logiciel.

## Ordre d'exécution recommandé
1. Phase 1 (BVH) — seul point bloquant réel, impacte tous les modes (pathtracer/rasterizer MTLX et
   legacy partagent `bvh_props`/`bvh_surface`).
2. Retrait partiel de `three-mesh-bvh` de `package.json` dès Phase 1 validée.
3. Phase 2 (envmap) — indépendante.
4. Phase 3 (textures) — indépendante, la plus simple.
5. Phase 4 finale (nettoyage complet + revalidation).

## Points à trancher avant l'implémentation
- **Phase 1 format GPU** : garder le format `geomN/geomT/geomS` actuel (léger changement) ou basculer
  sur `verticesTex/normalsTex/vertexIndicesTex` façon GLSL-PathTracer-JS (plus fidèle à la source, plus
  de refactoring) ?
- **Phase 2 CDF importance sampling** : inclus dans ce chantier ou reporté (changerait le rendu/
  convergence) ?
- **Legacy pathtracer** (`Pathtracer legacy`, `pathtracedMaterial_legacy`, `bvh_props`) : migré aussi,
  ou laissé sur three-mesh-bvh (mode comparaison manuelle uniquement) ?

## Phase 5 — Alignement avec `D:\WebGL2\GLSL-PathTracer-JS\shaders\skeleton.glsl` (menu à trancher)

Constat (voir analyse du 2026-09-09) : notre route MTLX locale et `skeleton.glsl` partagent le même
socle utilitaire (Basis, GGX, Fresnel, PCG — `skeleton.glsl` déclare explicitement en avoir porté
`glsl/pathtracing/mtlx/common.glsl`), mais divergent sur toute l'infrastructure scène/lumières/
textures/uniforms. Chaque item ci-dessous est **indépendant** ; à choisir individuellement selon ce
qui doit réellement converger.

### Textures matériaux

> ⛔ **Décision (2026-09-09) : NON RETENU.** Investigation menée : le GLSL généré par le WASM
> MaterialX n'appelle pas `texture()` directement au site d'usage — il émet **une fonction partagée
> par type de nœud** (`mx_image_color3`, `mx_tiledimage_*`, `mx_hextiledimage_*`,
> `mx_triplanarprojection_*`, ...) prenant le sampler en paramètre `sampler2D` classique, réutilisée
> pour tous les bindings de ce type (ex. `image_color_file` et `image_roughness_file` partagent la
> même fonction `mx_hextiledimage_color3`, qui fait elle-même plusieurs `textureGrad()` internes).
> Basculer vers un atlas (`sampler2DArray` + index de calque) exigerait de réécrire la signature et le
> corps de chaque variante `mx_*image*`, plus chaque site d'appel, via des regex sur du texte généré à
> la volée — risque de régression silencieuse (rendu visuellement faux sans erreur de compilation)
> difficile à valider sur les 38 matériaux de la bibliothèque + tout `.mtlx` custom futur. Le gain
> attendu est purement architectural (pas de gain visuel), donc non retenu. **Le format actuel — un
> `uniform sampler2D` nommé par binding, généré par le dispatch WASM (`${parentName}_file`) — reste en
> place**, inchangé depuis la Phase 3.

- **Écart** : local = un `sampler2D` nommé par fichier texture (`${parentName}_file`, généré par le
  dispatch WASM) ; `skeleton.glsl` = un `materialsTex` + `samplerArrayBuffer textureMapsArrayTex`
  (atlas partagé indexé par matériau).
- **Étapes si alignement retenu** :
  1. Générer un atlas/texture-array au chargement (redimensionnement uniforme requis, ou
     `texture2DArray`/`samplerArrayBuffer` selon support WebGL2 réel du navigateur cible).
  2. Adapter `MtlxPathTracerHostShaderGenerator` (ou le dispatch runtime) pour émettre un index de
     texture au lieu d'un nom de sampler par binding.
  3. Réécrire `createMtlxRouteTextureUniforms()`/`main.js` pour uploader l'atlas plutôt que N
     `Texture` individuelles.
  4. Impact : rupture de compatibilité avec le format `${parentName}_file` actuel, à valider sur tous
     les fixtures `mtlx-input/*`.

### Envmap

> ⚠️ **Statut (2026-09-09) : IMPLÉMENTÉ MAIS DÉSACTIVÉ PAR DÉFAUT (bug non résolu).**
> Implémenté : `src/envmap/hdrLoader.js` construit désormais la CDF de luminance (somme cumulative
> plate, ordre raster — même convention que `EnvironmentMap.buildCDF()` de GLSL-PathTracer-JS, pas une
> vraie décomposition marginale/conditionnelle 2D) en même temps que la conversion RGBE→half-float ;
> `src/envmap/envLoader.js` construit en plus une texture équirect dédiée (`flipY=false`, indépendante
> du `envMap`/`envMapLatLong` three.js en `flipY=true`) et la texture CDF (`R32F`/`NEAREST`) ; le GLSL
> (`glsl/pathtracing/mtlx/pathtracer.glsl`) porte `envMapBinarySearch`/`envMapUvToDir`/`envMapDirToUv`/
> `envMapPdfFromUv` et réécrit `skySample`/`skyPdf` pour échantillonner par CDF quand disponible.
> **Bug constaté** : activé, le rendu devient blanc/surexposé (confirmé par test A/B : désactivé →
> rendu correct ; activé → blanc). La formule de conversion pdf uv→angle-solide a été revérifiée ligne
> par ligne contre `skeleton.glsl`/PBRT et semble correcte ; cause racine non identifiée (suspicion :
> échelle `envMapTotalSum` vs `luminance(color)` échantillonné, ou un problème d'upload de texture
> `R32F`/`RedFormat` non détecté silencieusement). **La fonctionnalité reste en place mais gardée
> derrière `params.env_cdf_sampling` (défaut `false`, activable via `?env_cdf_sampling=true`)** ; tant
> que ce flag est `false`, le comportement est strictement identique à avant (cosinus-hémisphère).
> Le modèle soleil analytique n'a pas été touché (reste actif en parallèle, MIS inchangé quand le CDF
> est désactivé).

- **Écart** : local = ciel+soleil analytiques (`skyRadiance`/`sunRadiance`, uniforms `skyPower`/
  `skyColor`/`sunDir`/`sunAngularSize`/`sunPower`/`sunColor`), pas de CDF ; `skeleton.glsl` =
  importance sampling complet de la HDRI (`envMapTex`+`envMapCDFTex`, `BinarySearch`/`SampleEnvMap`/
  `EvalEnvMap`, MIS solid-angle).
- **Étapes si alignement retenu** :
  1. Construire la CDF de luminance (ligne puis colonne) côté JS au chargement de l'env map
     (`src/envmap/envLoader.js`), en plus de la texture RGBA déjà chargée nativement (Phase 2).
  2. Uploader la CDF en texture (`envMapCDFTex`) + uniforms `envMapRes`/`envMapTotalSum`/
     `envMapIntensity`/`envMapRot`.
  3. Porter `BinarySearch()`/`SampleEnvMap()`/`EvalEnvMap()` dans `glsl/pathtracing/mtlx/pathtracer.glsl`
     et les brancher dans la boucle NEE/MIS à la place de (ou en complément de) `skyRadiance`.
  4. Décider du sort du modèle soleil analytique actuel : conservé en parallèle (double stratégie MIS)
     ou remplacé entièrement par l'échantillonnage HDRI.
  5. Impact : change la convergence/le bruit visuel sur toutes les scènes utilisant un environnement
     HDRI — nécessite une repasse de validation visuelle complète (toutes scènes, `--gpu=false`).
- **Prochaine étape (à froid)** : instrumenter (dump JS des premières valeurs de `cdf`/`totalSum`,
  vérifier via un log GLSL temporaire — ex. sortie debug couleur — la valeur de `pdf_sky` réellement
  calculée sur quelques pixels) avant de retenter l'activation.

### Lights

> ✅ **Statut (2026-09-09) : IMPLÉMENTÉ ET VALIDÉ.** `mtlxLight*[MAX_MTLX_LIGHTS]` (8 tableaux
> d'uniforms) remplacés par une texture unique `mtlxLightsTex` (6 texels RGBA/lumière, une ligne par
> lumière, lue via `GetMtlxLight(i)` dans `glsl/pathtracing/mtlx/pathtracer.glsl`) — plus de
> recompilation shader liée au nombre de lumières (`mtlxLightCount` reste un simple uniform int).
> Type **quad** (lumière surfacique) ajouté (`type=3`) : échantillonnage uniforme de l'aire, pdf
> repliée dans le radiance retournée (cohérent avec le schéma MIS delta-light existant de `LiDirect`).
> Sphère non implémentée (seul quad a été fait, pour limiter le risque). Testé via
> `?mtlx_lights_json=` (aucune fixture `mtlx-input/*` ne définit de vraie lumière) : point/spot/
> directional revalidés (lueur rouge visible), quad validé (teinte bleue visible avec `skyPower=0`
> pour isoler l'effet — sinon noyé par l'env map dominante). Portée limitée à
> `glsl/pathtracing/mtlx/*` ; `glsl/rasterization/mtlx/common.glsl` conserve ses anciens tableaux
> `mtlxLight*[MAX_MTLX_LIGHTS]` inutilisés (jamais lus par `rasterizer.glsl`, donc sans risque) —
> non touché pour limiter la portée du changement.

- **Écart** : local = tableaux d'uniforms à taille fixe (`mtlxLight*[MAX_MTLX_LIGHTS]`, point/
  directional/spot uniquement, `MAX_MTLX_LIGHTS=1` par défaut) ; `skeleton.glsl` = `lightsTex`
  (nombre arbitraire, `GetLight(i)`) + support des **lumières surfaciques** (quad/sphère).
- **Étapes si alignement retenu** :
  1. Remplacer les tableaux d'uniforms `mtlxLight*` par une texture `lightsTex` (5 `vec4`/lumière,
     format identique à `skeleton.glsl` pour rester comparable).
  2. Relever/supprimer la limite `MAX_MTLX_LIGHTS` côté `main.js` (`createMtlxLightUniforms`,
     `materialDefines`).
  3. Ajouter le type "surfacique" (quad/sphère) : échantillonnage par aire + PDF, absent aujourd'hui
     de `extractMtlxLights`/`mtlxLightSample`.
  4. Impact : change le binding lumière dans `glsl/pathtracing/mtlx/pathtracer.glsl` et
     `glsl/rasterization/mtlx/rasterizer.glsl` (qui lit aussi `mtlxLight*` pour l'ombre directionnelle).

### Matériaux
- **Écart** : local = un seul matériau MaterialX actif par draw (`MATERIAL_OPENPBR`, généré au build)
  + 2 matériaux analytiques fixes (`MATERIAL_PROPS`, `MATERIAL_GROUND`) ; `skeleton.glsl` =
  `materialsTex` + sélection par instance via `transformsTex`, plusieurs matériaux par scène choisis
  à l'exécution.
- **Étapes si alignement retenu** (chantier lourd, dépend de l'atlas textures ci-dessus) :
  1. Étendre `MtlxPathTracerHostShaderGenerator` pour émettre un dispatch multi-matériaux (actuellement
     un seul `generated_bsdf_dispatch.glsl` par sélection, cf. spec 003) — remise en cause de l'
     hypothèse "un seul matériau MaterialX par route" du chantier 003.
  2. Ajouter un `materialsTex`/index de matériau par triangle (actuellement le seul distingo est le
     flag `neutralFlag` dans `geomS_surface`).
  3. Impact : chantier majeur, transverse à la génération WASM ; à ne considérer qu'après un besoin
     produit explicite (scènes multi-matériaux MTLX).

### Uniforms / infrastructure de rendu

> ⚠️ **Statut (2026-09-09) : ÉVALUÉ — aucun changement de code net-positif identifié.**
> Revue de chacun des 4 sous-items :
> 1. **Rendu tuilé** : le rendu actuel utilise déjà une `WebGLRenderTarget` (FBO) avec accumulation
>    par alpha-blend (`accumulation_weight = 1/(samples+1)`, `renderer.autoClear = samples===0`), donc
>    ce n'est pas un rendu "direct-to-canvas" bloquant comme le préjugé initial le suggérait — chaque
>    passe est déjà une frame complète accumulée dans un FBO, pilotée par `requestAnimationFrame` (donc
>    non bloquante pour le thread UI). Le vrai gain du tuilage de `skeleton.glsl` (découper UNE frame
>    en sous-tuiles pour rester réactif à très haute résolution/samples) reste un écart réel, mais
>    implémenter un FBO ping-pong tuilé est le changement **le plus risqué de tout ce chantier
>    Phase 5** (touche `render()`, tous les shaders consommant `accumulation_weight`/`samples`, et
>    l'assemblage NDC caméra) — non entrepris ici sans un besoin produit concret (utilisateurs qui
>    demandent explicitement des résolutions/samples plus élevés que ce que permet le rendu actuel).
> 2. **`uLowRes`** : chez `skeleton.glsl`, ce mode évite de compiler deux fois le lourd dispatch
>    MaterialX généré (un programme "preview" séparé). Chez nous, il n'existe qu'**un seul programme**
>    par configuration (pas de variante preview/full séparée), donc le problème que `uLowRes` résout
>    ne se pose pas ici — le contrôle `render_size` (`256x256`/`512x512`/`max`) + `paused` couvre déjà
>    le besoin d'aperçu réactif sans double compilation.
> 3. **TLAS/BLAS multi-instance** : le plan lui-même l'exclut ("ne s'applique que si... hors périmètre
>    actuel"). Non fait, intentionnellement.
> 4. **Retrait de la validation de contrat WASM** : le plan lui-même l'exclut explicitement
>    ("à garder même en cas d'alignement — pas un écart à corriger"). Non fait, intentionnellement.
>
> Conclusion : items 3 et 4 étaient déjà exclus par le plan ; items 1 et 2 ont été réévalués et ne
> justifient pas un changement de code ici (1 = risque disproportionné sans besoin produit identifié,
> 2 = problème inexistant dans notre architecture à programme unique). Aucune modification de code
> apportée pour cette catégorie.

- **Écart** : local = accumulation scalaire (`samples`/`accumulation_weight`, sans FBO tuilé), matrices
  caméra three.js, BVH combiné unique (`bvh_surface`/`bvh_props`), validation de contrat WASM
  (`strict_failure_enabled`/`generated_contract_valid`) ; `skeleton.glsl` = accumulation FBO ping-pong
  tuilée (`accumTexture`/`tileOffset`/`invNumTiles`), TLAS/BLAS multi-instance
  (`verticesTex`/`normalsTex`/`vertexIndicesTex`/`transformsTex`), `uLowRes` (aperçu basse résolution).
- **Étapes si alignement retenu** (à ne prendre qu'une par une, indépendantes) :
  1. **Rendu tuilé** : remplacer `render()`/`FullScreenQuad` (accumulation directe) par un FBO
     ping-pong + `tileOffset`/`invNumTiles`, pour supporter des résolutions/samples plus élevés sans
     bloquer le thread GPU. Change `main.js` (boucle de rendu) et tous les shaders consommant
     `accumulation_weight`/`samples`.
  2. **Aperçu basse résolution (`uLowRes`)** : ajouter un mode preview mono-échantillon partageant le
     même programme shader (évite une double compilation du dispatch MaterialX généré, lourd).
  3. **TLAS/BLAS multi-instance** : ne s'applique que si le viewer doit un jour supporter plusieurs
     instances de la même géométrie (hors périmètre actuel : une seule géométrie combinée par scène).
  4. **Retrait de la validation de contrat WASM** (`strict_failure_enabled`/`generated_contract_valid`)
     : spécifique à ce viewer (garde-fou spec 002/003), à garder même en cas d'alignement — pas un
     écart à corriger mais une fonctionnalité locale intentionnelle.

### Recommandation de priorisation (parmi ce qui reste ouvert)
1. Envmap (CDF importance sampling) — implémenté, désactivé par défaut (bug non résolu, voir ci-dessus).
2. Lights (texture + lumières surfaciques) — fait et validé.
3. ~~Uniforms/rendu tuilé~~ — évalué, aucun changement retenu (voir ci-dessus : items 3/4 exclus par
   le plan, items 1/2 réévalués sans gain net identifiable dans notre architecture actuelle).
4. ~~Textures (atlas)~~ — **non retenu** (décision 2026-09-09, voir ci-dessus).
5. Matériaux (multi-matériaux par scène) — chantier le plus lourd, à ne faire que si un besoin produit
   explicite apparaît. Seul item de la Phase 5 encore totalement ouvert.
