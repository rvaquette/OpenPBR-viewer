# T007 - Adaptation des geometries

Date : 2026-10-05. Verdict : PASS. Adaptateur isole, backend reference non active.

## API et donnees

src/bvh/referenceSceneAdapter.js expose adaptReferenceGeometry(geometry, options).
Entree : BufferGeometry Three.js statique, indexee ou non indexee, triangle-list.
Les attributs sont lus avec getX/getY/getZ/getW : buffers entrelaces et valeurs
normalisees sont decodes comme par Three.js, pas par acces brut a leur typed array.
Options : name, materialID commun explicite ou materialIDs indexes par materialIndex.
Sans binding, materialID=null est un etat non resolu, pas un fallback de shading.
Les instances devront recevoir leur materialID valide au jalon 4.

Sortie version 1 : space=object, transformsApplied=false, primitives,
sourceTriangleCount, triangleCount et empty. Une primitive par groupe actif :

- verticesUVX : Vec4 XYZ/U ; normalsUVY : Vec4 normal/V, format de la reference.
- tangents : Vec4 XYZ/signe si presentes ; vec3 source -> signe +1 comme le local.
- triangleBounds : BBox objet par triangle, calcul equivalent aux grow de Mesh.buildBVH.
- sourceTriangleIDs et sourceVertexIndices : tracabilite de l'expansion indexee.
- groupIndex, materialIndex, materialID et flags hasNormals/hasUvs/hasTangents.
- extraAttributes : autres attributs de 1 a 4 composantes, dont neutralFlag,
  etendus dans le meme ordre de sommets ; aucune conversion de ce flag en materialID.
- degenerateTriangleIDs : triangles de surface nulle conserves et identifies.

Pas d'application de matrice, changement de winding, normalisation des normales
fournies ou inversion UV.y. L'inversion du loader OBJ distant n'est pas appliquee
aux UV deja charges par glTF/Three.js. Normales absentes : normale geometrique
objet, axe Z stable pour triangle degenere, flag hasNormals=false conserve.
UV absents : fallback par triangle (0,0)/(0,1)/(1,1), flag hasUvs=false.
L'adaptateur traite les positions de base ; il ne bake pas animations/skinning/morphs.

## Topologie et erreurs

Groupes : plages alignees aux triangles, sans recouvrement ni trous, couvrant les
elements source. drawRange est ensuite intersecte avec ces plages comme une selection
de rendu. Aucune primitive pour une plage vide ; geometrie vide explicite sans appeler
le constructeur BVH upstream. Le compteur source reste distinct des triangles dessines.

Refus nommes : type/position invalide, nombre de triangles incomplet, indices hors
bounds/non entiers, groupes non partitionnes ou mal alignes, tailles/comptes d'attributs
incompatibles, valeurs non finies/non representables en float32 et IDs materiaux invalides.
Un tableau materialIDs incomplet ne produit pas de materiau implicite.
Les attributs de plus de quatre composantes sont rejetes explicitement, pas tronques.

## Configuration et scope

src/bvh/package.json declare ESM uniquement dans ce sous-dossier ; pas de changement
au package.json racine edite par l'utilisateur. allowJs=true dans la configuration
du runner permet les imports .js upstream -> .ts depuis l'adaptateur JS. Sources TS,
leurs hashes et leurs algorithmes restent inchanges.

L'adaptateur n'est pas importe par main.js. Three.js reste actif. Pas de build BLAS,
reordonnancement, upload GPU, TLAS, extraction de scene ou changement GLSL en T007.
T008 reprend le choix Bvh/SplitBvh et les oracles structurels ; T009 traite transforms
et instances. Les groupes sont des donnees de primitive glTF, pas un nouveau loader glTF.

## Verification

```powershell
npm test
npm run build
```

26 tests passes, dont 7 controles T007 : indexe/non indexe et source intacte,
groupes/drawRange/IDs, interleaved/normalized/UV/tangentes/neutralFlag, vide/degeneres,
refus malformed, tangentes vec3 et bundle navigateur isole.
Le build garde les bundles main-BQ2qQFRd.js/mobile-HaSA8any.js de T006, sans
activation de l'adaptateur. Aucun test de rayons/GPU reference n'est revendique.