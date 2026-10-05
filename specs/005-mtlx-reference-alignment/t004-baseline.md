# T004 - Baseline de captures

Date : 2026-10-05. Verdict : PASS pour le perimetre de capture accepte.
Pas de migration BVH/loader ni de modification du shading pour cette baseline.

## Preuves

- artifacts/mtlx-reference-alignment/01-baseline/baseline-manifest.json : 19 cas,
  16 locaux et 3 reference non-MTLX, PNG 256x256 et 128 SPP, hashes PNG/rapports.
- baseline-contact-sheet.png dans le meme dossier : planche examinee visuellement.
- Chaque cas local contient viewer.json, uniforms observes, logs, sources GLSL et
  wasm-generated-dispatch.glsl. Backend logiciel et denoise=false controles.
- Chaque reference contient logs en direct, browser.ndjson, viewer.json, shader
  compile complet et sa metadata. SwiftShader/128 SPP/absence de closure MTLX verifies.
- Disney Gold repete dans t004-20261005-repeatability : images RGB strictement
  identiques, RMSE normalisee 0 et difference maximale par canal 0.

Les cohortes sont agregees par cas : les captures reussies de la campagne locale
interrompue restent valides ; son normal-map echoue est conserve et remplace dans
la selection par une capture reussie de la fixture complete. Une tentative reference
interrompue est aussi conservee ; seules les captures avec verdict PASS sont retenues.

## Corrections du harness et du corpus

1. Disney Gold lie explicitement mtlx-input/disney_principled_gold_test.mtlx.
   Un plastique bleu est ajoute au corpus.
   Contrastes chromatiques verifies automatiquement, pas de conversion grayscale.
2. Normal-map utilise mtlx-input/brick_atlas_path/brick_procedural.mtlx et ses six
   textures presentes ; le premier document choisi referencait des fichiers absents.
3. Racine reference normalisee par path.resolve : le serveur Windows compare
   maintenant des chemins avec les memes separateurs, eliminant le faux 404 index.html.
4. maxspp de la reference est porte au budget demande dans une scene temporaire,
   sans modifier le fichier .scene original. La scene or auteur etait limitee a 32.
5. stdout/stderr persistants, phases et evenements navigateur en direct, fail-fast
   sur navigation HTTP invalide et erreurs JS ; rapports RUNNING/PASS/FAIL explicites.

## Revue et limites

La planche montre les geometries attendues, les textures de sol, le normal-map,
l'or, le plastique bleu, l'iridescence et les scenes Cornell avec murs colores.
Cette revue par l'assistant est un controle de capture, pas une recette artistique
par l'utilisateur ni une preuve d'exactitude physique des BSDF.

Anomalies initiales a conserver pour les comparaisons : les objets des fixtures
disney-principled et usd-preview sont nettement sombres ; transmission et volumes
restent bruites a 128 SPP. Ces rendus sont captures avant migration, pas corriges
ou qualifies comme regressions BVH. Les materiaux neutres gris restent intentionnels.
Les couleurs locales et distantes ne doivent pas etre comparees pixel a pixel :
materiaux/integrateurs/environnements distincts. Le local est l'oracle MTLX.

Les temps par cas et budgets proposes (temps mesure *1.25) sont dans le manifeste ;
ils concernent le meme environnement de capture et ne sont pas des garanties GPU.
Les limites GPU sont relevees dans les rapports locaux. La memoire GPU pic n'est
pas mesuree par ces snapshots ; la recette de ressources des jalons suivants reste requise.

Decision utilisateur : volet entrees HDR a faible SPP et sorties denoiser reporte
aux etapes 14-15. Aucun OIDN externe ou rendu MaterialX distant execute.
La baseline de pixels RGB n'est pas une entree HDR lineaire valide pour le denoiser.

Le manifeste conserve pending=manual-corpus-review, car il a ete ecrit avant cette
revue ; le present compte rendu acheve ce controle sans modifier les captures figees.
Repetabilite verifiee sur Disney Gold ; un seuil strict sur tous les cas n'est pas
deduit d'un seul temoin. Les tests de rayons/uniforms prevus restent prioritaires.

## Verification

```powershell
node --test tools/mtlx-reference-alignment/run.test.mjs
node tools/mtlx-reference-alignment/validate-baseline.mjs
```

9 tests du runner passes ; build viewer PASS (avertissements Vite preexistants).
La commande de validation controle fichiers, hashes, couverture, samples et revue.
T005 n'est pas commencee par la cloture de T004.