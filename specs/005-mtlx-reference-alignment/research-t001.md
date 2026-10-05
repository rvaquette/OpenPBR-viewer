# T001 - Releve de la reference

Date : 2026-10-04. Perimetre : inventaire et inspection statique, sans migration.
Exigences concernees : REQ-001 a REQ-008. T002 et la recette du jalon 0 restent ouverts.
Aucun renderer, generateur MaterialX ou denoiser distant n'a ete execute.

## Revisions et etat des depots

| Depot | Branche | HEAD | Etat observe avant T001 |
| --- | --- | --- | --- |
| Local | main | 5a863b2a81e72789dc588abd892d59ce0766788e | specs/005-mtlx-reference-alignment/ non suivi |
| Reference | 005-rebuild-mtlx-skeleton | f9cf1dd22e5538c7885807a3f8fc6d88d69dbe44 | sous-module scenes modifie |
| Reference/scenes | Sous-module | 4031c29a49fcb734341b94584330754bcb48a5b9 | M pathtracer/test_material_disney_gold.scene |

Les empreintes ci-dessous concernent les fichiers de travail, pas une supposition
de worktree propre. Ne pas restaurer ou modifier le fichier scene de l'utilisateur.
Pour une reprise ulterieure, verifier revisions ET empreintes ; noter toute divergence.

## Empreintes SHA-256

Chemins relatifs a D:/WebGL2/GLSL-PathTracer-JS. Hashes calcules sur les octets reels.

| Source | SHA-256 |
| --- | --- |
| package.json | 0c716820ab9df6116d38fa67db77d768407d1b364db62d59815322bc0f85cb06 |
| src/core/mesh.ts | 61b337b13110d22eca5ab3aabe35991c6a703c4c47366ba4f5b51e736ec28dca |
| src/core/pathtracer/pathtracerScene.ts | 02e5ce73b2a92c7135ed6957a9ec944d5ab84968023d2213e1e6e6036f68d491 |
| src/core/pathtracer/pathtracerRenderer.ts | 4d1d748a76eabebd3aa92df601c2cbb8448d1d3acb3428b4330f3fb2447c1c8c |
| src/core/pathtracer/loaders/sceneLoader.ts | 2da82c546366f63f13d2a6afcfab156b93afd17778a4c9f8ca1b56b12bcaee51 |
| src/bvh/bbox.ts | 7800495505574207fa6f379aaf05436cc2bbfa6e36b1187c92bd628983d30214 |
| src/bvh/bvh.ts | 69c1098ec447e321a4acda04f7f2a80254d1b12098868557eb9a84e02a8a0cc3 |
| src/bvh/splitBvh.ts | b2ce6a9a313b75a446881089790c12b345be69cd0aad50762f85091bf025b08d |
| src/bvh/bvhTranslator.ts | 1e74bbc9ccca4ab324b826553d768815913e84008c2ec5775caf423277e9e49f |
| shaders/common/closest_hit.glsl | 864af40b7f85ae4f08c4207231c286c816f41805552f3d183543b17ef329b70b |
| shaders/common/anyhit.glsl | e4ff7cdd408cb550ebddd4e8d4baacc33bd2efdda8b906e2ff3bf7ca9cde915d |
| src/external/denoiser/denoiser.js | 0362f90554f25660721233c26d975a8b47a1c7e0f929c8be3038bb7ca644274d |

## Licences relevees

- package.json distant declare MIT, mais aucune LICENSE globale n'a ete trouvee
  a la racine. Cette declaration ne suffit pas a attribuer une provenance precise
  a tous les modules TS ou aux assets.
- LICENSES/OpenPBR-viewer-rva-MIT.txt : MIT, Jamie Portsmouth, 2024. Notice identique
  au LICENSE local ; elle couvre le code ainsi attribue, pas automatiquement tout le depot.
- closest_hit.glsl et anyhit.glsl portent une notice MIT, Asif Ali, 2019.
  Conserver ces notices et verifier les autres shaders repris lors de leur inventaire.
- Le bundle denoiser contient notamment une notice Apache-2.0 Google, 2020.
  Ne pas traiter ce bundle tiers comme uniquement MIT. Inventaire de toutes ses
  notices et de la licence des poids du modele a completer avant redistribution.
- Licences/provenance des modules BVH TS sans notice explicite et des assets scene
  a confirmer au jalon 0 ; T001 releve cette incertitude, ne fournit pas un avis juridique.

## Construction BVH effective

### BLAS - src/core/mesh.ts

- Mesh construit `new SplitBvh(2.0, 64, 0, 0.001, 0)` : cout de traversee 2,
  64 bins, profondeur maximale de spatial split 0, seuil de recouvrement 0.001,
  budget de references supplementaires 0. Le spatial split n'est donc pas active
  par cette configuration, meme si la classe le permet.
- buildBVH calcule floor(verticesUVX.length / 3) triangles et leur AABB en espace
  objet, puis appelle bvh.build(bounds). Donnees de sommets developpees par triangle.
- Loader OBJ : parcours des indices par triplets, positions/UV.x dans verticesUVX,
  normales/UV.y dans normalsUVY ; UV.y est inverse (`1 - v`) a cet endroit.
  Ne pas generaliser cette inversion au chemin glTF sans inspection de son loader.
- SplitBvh produit des feuilles de moins de quatre primitives : le parcours GLSL
  doit boucler sur le count reel, pas supposer un triangle par feuille.

### TLAS et serialisation - PathtracerScene / BvhTranslator

- sceneBvh utilise `new Bvh(10.0, 64, false)` : 64 bins mais SAH desactive pour ce TLAS.
- createBLAS appelle mesh.buildBVH pour chaque mesh. createTLAS transforme les bounds
  objet de chaque BLAS par la matrice de l'instance, puis construit les bounds monde.
- processSceneAsync construit BLAS, TLAS puis appelle bvhTranslator.process.
- BLAS contigus avant TLAS ; topLevelIndex est la somme des node counts BLAS.
- LRLeaf.z = 0 : interne, x/y sont indices enfants.
  LRLeaf.z > 0 : feuille BLAS, x = offset triangles global, y = nombre de primitives.
  LRLeaf.z < 0 : feuille TLAS, x = racine BLAS, y = materialID, z = -instanceIndex-1.
- vertIndicesData est Int32Array : triangles reordonnes selon getIndices du BLAS,
  avec offsets de sommets globaux. verticesData/normalsData sont Float32Array vec4.
- transformsData est Float32Array, 16 floats par instance selon Mat4.data.
- rebuildInstances reconstruit le TLAS et appelle updateTLAS ; pas de rebuild BLAS.
  Test de reutilisation du traducteur et accumulation des racines requis a T010.

## Upload physique effectif

PathtracerRenderer appelle les helpers de src/core/renderer.ts ; c'est cette
abstraction qui decide largeur/hauteur, padding et format reel de texImage2D.

| Donnee | CPU | Format GPU / type | Texels par enregistrement | Unite distante |
| --- | --- | --- | --- | --- |
| BVH | Float32Array, 9 floats/noeud | RGB32F / RGB / FLOAT | 3 | 1 |
| Indices triangle | Int32Array, 3 indices | RGB32I / RGB_INTEGER / INT | 1 | 2 |
| Positions et U | Float32Array, vec4 | RGBA32F / RGBA / FLOAT | 1 | 3 |
| Normales et V | Float32Array, vec4 | RGBA32F / RGBA / FLOAT | 1 | 4 |
| Materiaux distants, non repris | Float32Array, vec4 | RGBA32F / RGBA / FLOAT | stride scene | 5 |
| Transform instance | Float32Array, 16 floats | RGBA32F / RGBA / FLOAT | 4 | 6 |
| Lumiere | Float32Array, 15 floats | RGB32F / RGB / FLOAT | 5 | 7 |

createBufferTexture/createBufferTextureInt : elements = length / channels,
width = min(Renderer.maxBufferTextureWidth, elements), height = ceil(elements/width).
Padding avec zeros jusqu'a width*height*channels. createTexture utilise Nearest
et ClampToEdge. Les limites de capacite et buffers vides restent a contractualiser.
topBVHIndex est envoye par uniform1i ; les unites ne doivent pas etre copiees
aveuglement dans le viewer, dont les bindings MTLX consomment aussi des samplers.

gles300.glsl fournit samplerBuffer -> sampler2D et isamplerBuffer -> isampler2D.
Fetch lineaire : x = index % textureSize.x, y = index / textureSize.x, mip 0.
Le parcours et les donnees CPU doivent partager exactement ce contrat.
Les rendertargets d'accumulation RGBA32F sont distincts des textures de scene.

## Corpus .scene observe

59 fichiers .scene, tous sous scenes/pathtracer/. Comptage textuel, pas validation
par le loader : presence camera=59, renderer=59, mesh=56, gltf=3, light=38,
materialx_document=14, materialx_inline_begin=0. Les groupes peuvent se recouvrir.
Un nom de fichier contenant materialx/inline n'est pas une preuve de son contenu.

| Fixture candidate | Usage pour la suite | Restriction |
| --- | --- | --- |
| test_material_disney_gold.scene | Mesh OBJ, camera 45 degres, quad+sphere, temoin non-MTLX | Worktree modifie, figer son hash avant capture |
| cornell_box_orig.scene | Geometrie/ombres simples | Confirmer configuration non-MTLX et ressources |
| cornell_box_sphere.scene | Sphere emettrice | Meme controle |
| hyperion_rect_lights.scene | Plusieurs quads et instances OBJ | Meme controle ; scene plus lourde |
| hyperion_sphere_light.scene | Lumiere sphere | Meme controle |
| hyperion_distant_light.scene | Lumiere distante | Meme controle |
| test_sphere_light_small/medium/large.scene | Variation du rayon emetteur | Trois fichiers distincts |
| jinx.scene | Chemin glTF | Inspection ressources/materiaux requise |
| materialx_tests_glass.scene | Syntaxe glTF/MTLX a parser | Pas de rendu MTLX distant |
| openpbr_rva_standard_shader_ball.scene | Syntaxe glTF/camera/affectations | Pas de rendu MTLX distant |

test_material_disney_gold.scene inspecte : resolution 1280x720, maxdepth 8,
maxspp 32, enabletonemap false ; camera (7.5,5,7), lookat (0,0,0), FOV 45 ;
cube/sphere/floor OBJ, materiaux gold/ground, une sphere et un quad.
Le champ specular du materiau ground figure dans ce fichier : son support effectif
dans sceneLoader doit etre classe explicitement par T002, pas suppose.

hyperion_rect_lights.scene inspecte : resolution 1280x720, maxdepth 3,
camera (-15,15,0), lookat origine, FOV 60 ; plusieurs meshes OBJ et transforms.
Le corpus demande donc au minimum OBJ ainsi que glTF/GLB selon les blocs gltf.
Disponibilite, droits de redistribution et validite de toutes les ressources non
etablis ici ; les fixtures ne sont ni copiees ni executees pendant T001.

## Verification de T001 et suite

Verification attendue : hashes des 12 sources toujours identiques ; HEAD des trois
depots conformes ; corpus de 59 scenes et compte des directives conforme ; presence
des parametres BLAS/TLAS et formats GPU ci-dessus dans les sources ; notices verifiees.
Ces assertions statiques ne prouvent pas le fonctionnement du rendu ou du loader.

Controle execute : PASS sur les 12 hashes, les trois revisions, les parametres
BLAS/TLAS, les formats GPU, les 59 scenes et leurs comptes de directives, et les
notices MIT/Apache citees. Commande reproductible depuis la racine du viewer :

```powershell
node specs/005-mtlx-reference-alignment/validate-t001.mjs
```

Le script lit uniquement les sources et interroge Git ; aucun renderer n'est lance.
Il ne remplace pas l'inspection semantique ni une verification des droits des assets.

T001 est termine pour son perimetre d'inventaire. T002 reste ouvert pour figer
les contrats, resoudre les licences manquantes, inventorier les ressources du denoiser
et sa couleur/HDR, definir erreurs/priorites camera/lumieres et selectionner les
fixtures non-MTLX executables. Le jalon 0 ne doit pas etre marque PASS sur T001 seul.