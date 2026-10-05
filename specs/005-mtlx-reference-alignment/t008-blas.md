# T008 - Construction BLAS de reference

Date : 2026-10-05. Verdict : PASS pour la construction CPU et ses oracles structurels.
Backend reference non active ; sources upstream inchangees.

## API et profils

src/bvh/referenceBlas.js fournit :

- createReferenceBvh('blas') : SplitBvh(2,64,0,0.001,0), comme Mesh distant.
- createReferenceBvh('tlas') : Bvh(10,64,false), fabrique pour le futur T009.
- buildReferenceBlas(primitive) : positions developpees de T007 -> nouveau maillage
  portant bvh, triangleBounds, blasStatus et blasStats.
- inspectReferenceBvh(bvh, primitiveBounds) : oracle de structure et couverture.

Les bornes sont recalculees depuis les XYZ de chaque triplet, par BBox.grow, comme
Mesh.buildBVH upstream. Les bounds caches de l'adaptateur ne sont pas pris comme
preuve de geometrie. Une instance neuve est construite a chaque appel, pour ne pas
reutiliser les indices/bounds mutables d'une ancienne construction upstream.
Un maillage vide retourne bvh=null, blasStatus=empty, bounds=[] et stats=null :
pas d'appel build([]), dont l'allocation upstream exige un nombre de primitives positif.
Cette sentinelle vide devra etre exclue du TLAS ou traitee explicitement par T009.

Les tableaux verticesUVX/normalsUVY/tangentes/attributs ne sont pas reordonnes ni
modifies. getIndices fournit la permutation des triangles pour la serialisation
future, exactement comme PathtracerScene upstream. Les flags/IDs de T007 sont conserves.

## Oracle independant et differentiel

Controle iteratif des noeuds : bounds finies et ordonnees, parent contenant enfants,
feuilles contenant leurs primitives, ranges de feuilles non chevauchants et complets,
references valides, absence de cycle/noeud partage, node count et hauteur coherents.
Permutation exacte : chaque primitive apparait une seule fois dans le profil source.
Les corruptions de references et de bounds introduites par les tests sont refusees.

Profil BLAS : profondeur de spatial split et budget de references supplementaires
a zero ; donc aucun doublon spatial attendu. Le code SplitBvh complet reste repris,
mais les variantes avec spatial splits actives ne sont ni activees ni certifiees ici.
Les feuilles de 1 a 3 triangles sont validees, leur count n'est pas suppose egal a 1.

Comparaison a des modules TS upstream isoles : 128 primitives a disposition permutee,
memes constructors et bounds reconstruits dans leurs classes Vec3/BBox propres.
Snapshots des bounds, children, ranges, hauteur et permutation identiques pour
SplitBvh et Bvh. Aucun MeshLoader, renderer ou generateur MTLX distant execute.
Ce controle differentiel complete l'oracle geometrique ; ce n'est pas un oracle de rayons.

## Verification

```powershell
npm test
npm run build
```

35 tests passes, dont 9 controles T008 : constructors, triangle/feuilles multiples,
cube et 64 coplanaires, 127 centroides identiques, 17 degeneres et vide,
constructions neuves/source intacte, corruptions, comparaison upstream, entrees
invalides/duplicats et bundle navigateur. Build PASS, bundle de production inchange.

Stats par BLAS : nodeCount, leafCount, maxDepth, maxLeafPrimitives,
packedPrimitiveCount, duplicateReferences. Les cas verifies terminent sans boucle
infinie ; aucune garantie universelle de profondeur/performance n'est deduite de ces tests.
Les sources importees et leurs six hashes restent intacts, sans patch algorithmique.

T008 et jalon 3 termines. Pas d'extraction de scene, TLAS d'instances, upload GPU,
parcours GLSL ou rendu avec ce backend ; T009 et les jalons suivants restent requis.