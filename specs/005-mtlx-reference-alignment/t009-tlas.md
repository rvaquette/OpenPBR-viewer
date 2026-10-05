# T009 - TLAS, instances et traduction CPU

Date : 2026-10-05. Verdict : PASS sur le chemin CPU. Backend reference non active.

## API

src/bvh/referenceScene.js expose buildReferenceScene(meshes, instances),
updateReferenceSceneInstances(scene, instances), normalizeReferenceTransform et
referenceInstanceBounds. Les meshes sont les primitives non vides construites en T008.
La table est unique et stable : plusieurs instances partagent un meshID et son BLAS,
pas plusieurs copies du meme record. Deux noms identiques ne suffisent pas a dedupliquer
des ressources distinctes ; le registre de chargement fera ce travail en amont.

Une instance contient meshID, materialID, name optionnel et worldTransform (ou transform).
Matrix4 Three.js, 16 valeurs column-major ou Mat4.data upstream en quatre colonnes
sont acceptes ; absence de transform = identite. Snapshot en Float32Array, sans modifier
la matrice source. Rejet des non-affines, NaN/Inf, singulieres et determinant/inverse
non representables en float32. Le determinant negatif est accepte.

Le monde est calcule depuis les bornes BLAS objet avec la formule upstream
right/up/forward, min/max des contributions des trois axes, puis translation.
Les positions/normales/UV/tangentes restent en espace objet. Les hierarchies glTF
doivent fournir matrixWorld au caller ; pas de nouvelle extraction glTF dans T009.

## Structure et offsets

TLAS : nouvelle instance Bvh(10,64,false) par construction, une instance par feuille.
Oracle T008 applique aux bounds d'instances. BvhTranslator.process est utilise pour
la premiere traduction ; les sources importees et leur encodage restent inchanges.

- BLAS avant TLAS, topLevelIndex = somme des node counts BLAS.
- Interne LRLeaf.z=0, children indices globaux.
- Feuille BLAS LRLeaf=(triangleOffset,count,1), avec offset triangles global.
- Feuille TLAS LRLeaf=(blasRoot,materialID,-instanceID-1).
- activeNodeCount distingue les noeuds utiles du dernier slot reserve upstream.
- geometry.vertexIndices est Int32Array, permutation BLAS et offsets vertices globaux.
- geometry.verticesUVX/normalsUVY sont copies une seule fois par mesh, pas par instance.
- meshRanges garde flags, tangentes et attributs supplementaires, dont neutralFlag.
- transforms garde les 16 floats column-major par instance ; pas d'upload GPU en T009.

IDs et capacites d'adressage sont valides numeriquement avant traduction. materialID
absent/non entier/hors limites ou mesh sans BLAS construit est refuse. L'existence
de l'ID dans le registre MTLX n'est pas prouvee par ce module CPU ; elle sera validee
a l'integration des materiaux, sans binding de shading implicite ici.
Une scene sans instances a nodes=[], tlas=null, sceneBounds=null et activeNodeCount=0.
La table de maillages peut rester disponible pour une mise a jour future. Un maillage
vide ne doit pas etre instancie dans cette API ; il reste une sentinelle de T008.

## Mise a jour

updateReferenceSceneInstances modifie le scene owner en place apres validation.
BLAS et geometry sont reutilises, sans reconstruire les BLAS ni changer leurs attributs.
Meme nombre d'instances : updateTLAS sur le traducteur existant, prefixe BLAS conserve.
Cardinalite modifiee ou retour depuis le vide : traducteur neuf et traduction complete,
pour eviter racines accumulees et slots de l'ancien TLAS. Nouveau TLAS/transforms dans
tous les cas. Un passage au vide retire le traducteur et les noeuds actifs.

Les meshes sont immuables pour la duree de vie de ce scene owner. Une signature
d'identites/buffers/comptes detecte les remplacements et reconstructions avant update.
Elle n'est pas un hash exhaustif de tous les contenus : modification en place des
vertices, normales ou nodes impose une reconstruction complete par le caller.
Pas de correctif du code vendor ; les constructions completes utilisent toujours
un traducteur neuf plutot que rappeler process sur ses caches prives.

## Verification

```powershell
npm test
npm run build
```

43 tests passes, dont 8 T009 : BLAS partage et IDs distincts ; offsets multi-mesh ;
8 coins d'un volume avec rotation/echelle non uniforme negative ; hierarchie parent/
enfant sans double transform ; update et cardinalite ; vide et refus matrices/refs ;
invalidation de topologie ; snapshots du traducteur upstream et bundle navigateur.
La comparaison upstream n'importe ni MeshLoader ni renderer/generateur distant.
Le bundle local utilise seulement les modules CPU et Matrix4 de Three.js.

Build PASS, bundles de production inchanges. Pas de scene loader, GPU, GLSL, oracle
de rayons ou rendu reference integre. T010 approfondit les cycles et invalidations ;
le jalon 4 n'est pas clos sur la seule implementation T009.