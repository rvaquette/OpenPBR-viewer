# Corpus et runner - T003

19 cas : 16 locaux, 3 temoins reference non-MTLX. Corpus defini dans corpus.json.
Reutilise launch_render.mjs/playwright-core pour le local, sharp pour les pixels et
le driver scripts/render-scene.mjs existant pour la reference. Aucune generation
MaterialX distante autorisee. T003 prepare les controles ; T004 capture la baseline.

## Commandes

Depuis la racine du viewer :

```powershell
node --test tools/mtlx-reference-alignment/run.test.mjs
node tools/mtlx-reference-alignment/run.mjs --validate
node tools/mtlx-reference-alignment/run.mjs --dry-run --target=all --profile=baseline
node tools/mtlx-reference-alignment/run.mjs --case=standard-shader-ball --samples=2 --size=64x64 --start-server=true --port=5193
```

T033 local paired smoke (raw and denoised variants for every local case):

```powershell
node tools/mtlx-reference-alignment/run.mjs --target=local --profile=smoke --samples=16 --size=64x64 --denoise=both --start-server=true --port=5201 --output=artifacts/mtlx-reference-alignment/t033-local-paired-16spp-64x64
```

T034 Android/Adreno smoke (requires an authorized Android device and Chrome remote debugging):

```powershell
$env:ADB_PATH = 'D:\platform-tools\adb.exe'
& $env:ADB_PATH devices -l
npm run build
node tools/mtlx-reference-alignment/adreno-t034-smoke.mjs
```

The denoiser runs by default. Set `$env:T034_DENOISE = 'false'` for a diagnostic run without it. The script records device/GPU details, 64 spp, raw-buffer integrity, denoiser status, renderer transitions, resize, browser errors, and direct ADB screen captures under `artifacts/mtlx-reference-alignment/t034-adreno/`.

For Kiwi, find its PID-suffixed DevTools socket, forward it to port 9223, and start a live Chromium logcat in a separate terminal:

```powershell
& $env:ADB_PATH shell cat /proc/net/unix | Select-String 'chrome_devtools_remote'
& $env:ADB_PATH forward tcp:9223 localabstract:chrome_devtools_remote_<PID>
& $env:ADB_PATH -s R5CW900CHQD logcat -T 1 -v time chromium:V '*:S' *> artifacts/mtlx-reference-alignment/t034-adreno/kiwi-chromium-live.txt
```

While logcat is streaming, run the smoke in another terminal:

```powershell
$env:T034_CDP_URL = 'http://127.0.0.1:9223'
$env:T034_EXPECT_PACKAGE = 'com.kiwibrowser.browser'
node tools/mtlx-reference-alignment/adreno-t034-smoke.mjs
```

Stop the logcat command with Ctrl+C after the smoke finishes. The logcat tag filter captures Chromium GPU/WebGL diagnostics without dumping unrelated Android app logs.

Apres T003, commandes pour T004 (non executees par la preparation) :

```powershell
node tools/mtlx-reference-alignment/run.mjs --target=local --profile=baseline --start-server=true --port=5193
node tools/mtlx-reference-alignment/run.mjs --target=reference --profile=baseline
```

Sans --start-server=true, un serveur Vite doit deja servir le viewer sur --port
(defaut 5181). Si ce port est occupe, choisir un autre port libre. Les serveurs crees
par le script de capture sont arretes apres chaque cas. --reference-root permet
de deplacer la reference, avec ses scenes, ses assets, son driver et ses dependances.
Le driver distant ne lance aucune build automatique : le dist distant doit etre
prepare et correspondre aux sources avant la baseline. Ses captures ne sont pas
un oracle du shading MTLX local.

--case=id1,id2 selectionne des cas ; --target=local|reference|all, --profile=smoke|baseline,
--samples=N, --size=WxH, --timeout-ms=N et --output=directory sont explicites.
Defauts : 256x256, smoke 32 SPP, baseline 128 SPP, timeout 25 minutes par cas.
Les sorties par defaut sont horodatees. Un dossier contenant report.json est refuse
pour conserver les resultats precedents, notamment les echecs.

## Controles et preuves

Local : mode exact Pathtracer MTLX, SwiftShader, denoise=false, environnement local
etzwihl_4k.jpg, CDF desactive, pas d'irradiance externe. Aucun executable OIDN lance.
Le parametre URL gpu=true active la route du viewer ; il ne contredit pas le flag
--gpu=false du navigateur, qui choisit le renderer logiciel.

Le rapport viewer.json optional de launch_render.mjs contient le mode observe via
__openpbrGpuInfo.app, samples/readiness, erreurs, context loss et taille du dispatch.
Les erreurs JS fatales pendant readiness interrompent la capture au lieu d'attendre
son timeout complet. Le runner refuse mauvais mode/scene, SPP insuffisants, erreurs
ou dispatch absent. Un PNG absent, de taille incorrecte ou constant est un echec.
Ces controles ne prouvent pas l'identite visuelle ou la qualite d'une image.

Reference : trois scenes non-MTLX approuvees et leurs hashes verifies avant execution,
aucun flag mtlx/generator/essl/hardware GPU. Activite de generation MTLX dans les
logs detectee en erreur. Le fonctionnement du driver distant reste a valider a T004.

Artefacts : rapport global avec revisions et empreintes, commandes et durees,
stdout/stderr par cas, PNG, dump GLSL, rapport viewer local et statistiques sharp.
stdout.log et stderr.log sont crees et alimentes des le lancement, pas seulement
a la fin du processus. report.json indique aussi le cas RUNNING pendant la capture.
Pour la reference, browser.ndjson conserve chaque evenement navigateur horodate :
console (tous niveaux en headless), pageerror, crash, requetes scene/mesh/shader/poids,
reponses HTTP et requestfailed. viewer.json contient l'etape courante et le dernier
evenement, puis le resultat PASS ou FAIL. Un heartbeat est emis toutes les 30 secondes.
Une navigation HTTP en erreur interrompt immediatement la capture.

Diagnostic court de la reference (dossier de sortie horodate par defaut) :

```powershell
node tools/mtlx-reference-alignment/run.mjs --target=reference --case=reference-cornell --samples=1 --size=64x64 --timeout-ms=90000
```

Lecture des fichiers pendant une capture, depuis une autre console PowerShell :

```powershell
Get-Content "<dossier-du-cas>/stdout.log" -Tail 50 -Wait
Get-Content "<dossier-du-cas>/stderr.log" -Tail 50 -Wait
Get-Content "<dossier-du-cas>/browser.ndjson" -Tail 20 -Wait
```

Ces traces ne changent ni le mode non-MTLX ni le backend logiciel. La capture sans
logs deja en cours doit etre relancee pour beneficier de cette instrumentation.
Les tags du corpus decrivent les cas prevus, pas un support rendu deja valide sur
les 18 cas. Les materiaux utilisent mtlx_url=/chemin-public : le viewer ajoute sa
base Vite lui-meme. Ne pas ajouter /OpenPBR-viewer/ une deuxieme fois.

## Verification T003

- npm run build : PASS (avertissements Vite CJS/chunk size preexistants).
- node --test tools/mtlx-reference-alignment/run.test.mjs : 5 passes, 0 echec.
- standard-shader-ball, 64x64, 2 SPP : PASS dans
  artifacts/mtlx-reference-alignment/t003-smoke/runner-validation-2/report.json.
- open-pbr explicite, 64x64, 2 SPP : PASS dans
  artifacts/mtlx-reference-alignment/t003-smoke/material-validation-2/report.json.
- Premiere capture sans serveur : echec consigne dans runner-validation/report.json.
- Premier chemin materiau double-prefixe : echec consigne dans material-validation/report.json,
  corrige dans le runner et couvert par test de commande.

Ni baseline 128 SPP, ni recette mobile, ni execution distante ou denoiser : T004 et
les autres jalons restent ouverts. npm test du projet est encore un placeholder ;
aucun package/dependance n'a ete modifie pour T003. Utiliser la commande ciblee ci-dessus.

## Etat T004 / diagnostic reference

Les 16 cas locaux ont des captures 256x256/128 SPP dans les cohortes
t004-20261005-colors, t004-20261005-local et t004-20261005-materials sous
artifacts/mtlx-reference-alignment/01-baseline/. Disney Gold lie explicitement son
document .mtlx ; un plastique bleu controle aussi la restitution des couleurs.
Le normal-map utilise brick_atlas_path et ses six textures locales ; l'echec initial
sur la fixture incomplete est conserve.

Le faux HTTP 404 est corrige : la racine du serveur reference doit etre normalisee
avec path.resolve avant son controle startsWith sur Windows. La scene auteur or
limite maxspp a 32 ; un overlay temporaire porte uniquement ce budget a 128.
Les sources distantes et leurs hashes restent intacts.

19 captures sont validees et figees dans baseline-manifest.json, avec planche
baseline-contact-sheet.png. 9 tests du runner passent ; les trois temoins distants
atteignent 128 SPP en SwiftShader, sans closure MaterialX dans le shader compile.
Les echecs/interruption precedents et leurs logs sont conserves.

```powershell
node tools/mtlx-reference-alignment/validate-baseline.mjs
```

T004 est terminee pour le perimetre de capture accepte. Revue, reproductibilite
du temoin or et limites : specs/005-mtlx-reference-alignment/t004-baseline.md.
Volet HDR/denoiser reporte explicitement par l'utilisateur aux etapes 14-15.
T005 n'a pas ete commencee par cette verification.