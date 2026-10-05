# T010 - Cycles, partage BLAS et invalidation

Date : 2026-10-05. Verdict : PASS sur le perimetre CPU. Pas de modification runtime.

Tests ajoutes dans reference-scene.test.ts, sans nouveau framework ni fichier
de tests parallele. Source referenceScene.js de T009 et modules upstream inchanges.

## Controles executes

1. 64 updates de meme cardinalite, alternant transforms, meshID et materialID :
   chaque snapshot compare a une scene construite a neuf. Meme geometry et meme
   traducteur ; prefixe BLAS conserve par identite, arbres/indices/attributs inchanges.
2. 40 transitions de cardinalite sur la sequence 0/1/5/2/0/3/3/1 : comparaison
   aux scenes neuves, passage au vide, retour depuis le vide, aucun ancien leaf actif.
3. 32 cycles A-B-A de constructions completes avec ordre des meshes inverse :
   traducteurs distincts, racines correctes, retour A identique au snapshot initial.
4. Updates invalides : meshID inconnu, materialID negatif ou hors float32 exact,
   matrice singuliere ou non finie. Ancien snapshot, TLAS et traducteur preserves.
5. Isolation des transforms : mutation de la Matrix4 source sans effet sur le
   snapshot publie ; ancien Float32Array conserve intact apres l'update suivant.
6. Reproduction du comportement upstream : deux process sur un meme traducteur
   avec meshes reordonnes produisent une racine stale. Le scene owner avec traducteur
   neuf donne la bonne racine ; aucune correction du fournisseur n'a ete appliquee.

Oracle de traduction : liens internes BLAS dans leur plage, liens internes TLAS
dans la plage active, bounds parents contenant les enfants, feuilles BLAS avec offsets
globaux/count corrects, une feuille TLAS par instance avec mesh root/materialID/
-instanceID-1 et bounds monde attendus. Comparaison des nodes actifs, geometry,
indices, transforms et sceneBounds aux reconstructions neuves.

## Decision sur le traducteur

Le defaut upstream de BvhTranslator.process accumulant bvhRootStartIndices est
maintenant reproduit explicitement dans la suite. Strategie validee : process sur
un traducteur neuf pour les constructions completes/changements de cardinalite,
updateTLAS sur le traducteur existant seulement pour une mise a jour compatible.
Les hashes et corps algorithmiques des sources importees restent preserves.

Ces tests ne changent pas le contrat d'immutabilite des meshes : les remplacements
de buffers/topologie sont detectes par la signature T009 ; les modifications en
place imposees par un caller doivent encore declencher un rebuild complet.
Les IDs sont controles numeriquement, pas resolus dans un registre MaterialX ici.

## Verification et limites

```powershell
npm test
npm run build
```

49 tests passent (43 precedents + 6 T010), zero echec. Build PASS et bundles de
production inchanges. Les 32 cycles A-B-A representent 96 constructions completes
en plus des comparaisons neuves des updates et transitions.

Le jalon 4 CPU est valide. Pas d'oracle de rayons, mesure de fuite GPU, uploads ou
parcours GLSL dans cette recette ; ils restent aux jalons suivants. La reference
reste non activable dans le viewer, Three.js demeure le backend courant.
T011 n'est pas commencee par la cloture de T010.