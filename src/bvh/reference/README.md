# Reference BVH - T005

Sources TS reprises depuis GLSL-PathTracer-JS, revision et SHA-256 dans SOURCES.json.
Pas de modification des algorithmes. BVH/BBox/SplitBvh/BvhTranslator sous bvh/,
Vec3/Vec4 sous math/. Vec2 et Mat4 ne sont pas necessaires a ce graphe.

Seule adaptation du fichier upstream : l'import Mesh/MeshInstance du traducteur
devient import type. core/mesh.ts declare uniquement les champs consommes ici,
sans loader, DOM, renderer, MaterialX ou geometrie concrete. Les adaptateurs de
scene pourront fournir ces structures aux etapes suivantes.

Les chemins .js des imports TS upstream sont conserves. Le compilateur de Vite
les resout vers les sources .ts ; aucun .js genere n'est ajoute au repertoire.
Le runner TS est configure par T006 (tsx 4.20.6, npm test/test:bvh-reference).
main.js n'importe pas ces modules : Three.js reste actif pour toutes les routes,
le backend reference est refuse explicitement tant qu'il n'est pas pret et aucun
GLSL n'est change. Configuration tools/mtlx-reference-alignment/tsconfig.json.

UPSTREAM-NOTICES.txt conserve les notices MIT AMD RadeonRays et Asif Ali du depot
C++ hote. La filiation est detaillee dans specs/005-mtlx-reference-alignment/
bvh-provenance.json. Les attributions d'adaptations TS encore ouvertes ne sont pas
inventees par cette copie ; conserver ces notices avec toute redistribution.

Commandes depuis la racine du viewer :

```powershell
node tools/mtlx-reference-alignment/import-reference-bvh.mjs
node --test tools/mtlx-reference-alignment/reference-import.test.mjs
npm run test:bvh-reference
```

L'import mecanique refuse des sources dont les hashes ont change et refuse
d'ecraser une copie locale modifiee. Il sert a reproduire T005, pas a mettre a jour
automatiquement le fournisseur. core/mesh.ts reste une declaration locale manuelle.
Les tests comparent les octets, compilent le graphe en memoire et executent une
construction minimale. Ils ne remplacent pas les tests d'oracle/rayons de T007-T010.
Les bugs upstream connus ou potentiels (reutilisation du traducteur, vide,
degenerescence, bornes) restent volontairement inchanges pendant cette reprise.