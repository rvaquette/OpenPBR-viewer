# T002 - Contrats de reprise, version 1

Date : 2026-10-04. Normatif pour le futur port, pas une declaration de support runtime.
Sources et revisions : research-t001.md. Aucun rendu MTLX distant autorise.
La table scene-directives.json est l'autorite pour le classement des directives.

## C01 - Hit et ombres [REQ-001, REQ-003]

Rayon monde : origine finie, direction unitaire, intervalle ouvert (tMin,tMax),
tMin explicite non negatif, tMax positif. Les adaptateurs des appels locaux fournissent
ces bornes ; aucun epsilon global independant de l'echelle n'est ajoute en secret.
Hit : t fini dans l'intervalle, position = origin + t*direction, Ng/Ns monde unitaires,
tangente monde orthogonalisee et handedness, UV, barycentriques vec3 de somme 1,
triangleID, instanceID et materialID distincts. Pas de shading a l'interieur du BVH.
Ng provient des positions transformees ; Ns par inverse-transpose, tangente par
transform lineaire. Echelles negatives traitent winding/handedness explicitement.
Pas de normalisation du rayon objet : le t monde reste comparable entre instances.
Front/back face conserve ; l'orientation locale du shading reste dans l'integrateur.
UV ou normales absentes : fallback local documente ; UV degeneres : tangente stable,
pas de division par zero. Miss ne fournit aucune donnee reutilisable comme hit.
Any-hit renvoie la visibilite sur le meme intervalle et preserve les filtres MTLX
actuels opaque/thinwalled ; ne pas importer l'alpha-test distant ou changer les volumes.
Oracles : 10 000 rayons CPU/GPU, epsilon t relatif 1e-4, barycentriques 1e-4,
normales/tangentes erreur composante 1e-4 sur fixtures non degeneres ; ties d'aretes
acceptes uniquement si position/geometrie equivalente, jamais si materialID different.

## C02 - Textures et BVH [REQ-002, REQ-003]

| Buffer | Type CPU logique | Format reference | Format physique local | Taille logique |
| --- | --- | --- | --- | --- |
| BVH | Float32Array | RGB32F sampler2D | RGBA32F, w=0 | 9 floats/noeud |
| Triangles | Int32Array | RGB32I isampler2D | RGBA32I, w=0 | 3 indices/triangle |
| Vertices/U | Float32Array | RGBA32F sampler2D | RGBA32F | 4 floats/sommet |
| Normals/V | Float32Array | RGBA32F sampler2D | RGBA32F | 4 floats/sommet |
| Transforms | Float32Array | RGBA32F sampler2D | RGBA32F | 16 floats/instance |
| Lumieres reference | Float32Array | RGB32F sampler2D | A definir au port lumieres | 15 floats/lumiere |

Decision utilisateur T011 du 2026-10-05 : Three.js r159 ne supporte pas les formats
RGB demandes ; chaque texel logique RGB est stocke en RGBA avec w=0. Adressage
et lectures .xyz inchanges, surcout RGB de 1/3 hors padding. Ce changement ne
definit pas encore le stockage des lumieres. Evidence : t011-gpu-textures.md.

Nearest/ClampToEdge, pas de mipmaps/colorSpace/flipY. Texel logique index ->
(index % width, floor(index/width)), niveau 0. Padding zero hors compte logique.
width=min(4096,MAX_TEXTURE_SIZE,max(1,texelCount)); height=max(1,ceil(texelCount/width)).
Verifier height<=MAX_TEXTURE_SIZE et budget complet des samplers MTLX avant upload.
Buffers vides : texture sentinelle 1x1 zero, count=0 ; aucun acces autorise.
Indices/nodes/materialIDs/instanceIDs en float doivent etre des entiers exacts <=2^24-1 ;
indices vertices Int32 non negatifs et dans leur buffer. Rejeter depassement, pas arrondir.
BVH interne LRLeaf=(left,right,0), feuille BLAS=(triangleOffset,count,1), feuille TLAS=
(blasRoot,materialID,-instanceID-1). Tous les offsets sont globaux, BLAS avant TLAS.
topBVHIndex entier explicite ; count=0 force miss avant fetch racine.
Pile de 64 entiers initiale reference : borne verifiee pour TLAS+BLAS et sentinelles,
si non prouvee lever BVH_STACK_CAPACITY avant rendu, jamais tronquer la traversee.
Preserver samplers plats pour Adreno. Aucun binding fixe distant impose au viewer.

## C03 - Instances et materiaux [REQ-001, REQ-002, REQ-004]

Maillage deduplique par identite ressource+primitive+attributs, BLAS en espace objet.
Instance=(meshID,materialID,worldTransform,name), IDs stables pendant une revision scene.
Geometries indexees/non indexees et groupes glTF explicites, pas de double transform.
Transforms GPU : colonnes mat4, 16 floats, multiplication GLSL M*vec4.
Syntaxe matrix .scene : 16 valeurs row-major, translation aux positions 3/7/11,
transposition unique pour le buffer column-major, comme le loader distant inspecte.
TRS : equivalent monde T*R*S ; la source Mat4 row-major calcule S.multiply(R).multiply(T).
Quaternion xyzw normalise non nul, scale par defaut (1,1,1), position zero, rotation identite.
Matrix prioritaire sur TRS ; avertissement si les deux sont presentes. Reject matrice
non finie, non affine, singuliere ; determinant negatif permis. GlTF parents inclus.
Update transform reconstruit TLAS/transforms sans BLAS ; changement de topologie
reconstruit la traduction complete. Le traducteur ne conserve pas de racines perimees.
materialID adresse le registre MTLX local, pas un flag ni le materialsTex distant.
Tous les hooks prepare/sample/evaluate/emission/opaque/thinwalled/milieu utilisent
le materiau touche. Sources MTLX heterogenes ne sont pas reduites a une closure partagee.
Un materiau non-MTLX requiert un binding local explicite ou SCENE_MATERIAL_UNBOUND ;
aucune conversion Disney -> MTLX approximative et aucun BSDF distant implicite.

## C04 - Camera [REQ-005]

Une camera active par scene ; si absente, framing bounds local explicite. Position/lookat
finies et distinctes ; forward normalise vers lookat, right=cross(forward,worldUp),
up=cross(right,forward), worldUp=(0,1,0), axe alternatif stable si parallele.
Matrix prioritaire : position=translation, forward=troisieme colonne, lookat=position+forward.
Comme la reference, roll matrix non conserve par ce chemin lookat ; diagnostic CAMERA_ROLL_DROPPED.
FOV .scene HORIZONTAL en degres (0,180), converti radians une fois : source tile.glsl
et preview.glsl, pas skeleton.glsl MTLX ni computeViewProjectionMatrix.
Sans jitter : d=(2*uv-1), scale=tan(fovH/2), ray=normalize(forward + right*d.x*scale
+ up*d.y*(height/width)*scale). Three.js recoit le FOV vertical equivalent
fovV=2*atan(tan(fovH/2)*height/width) ; pas de simple affectation camera.fov=fovH.
Centre/coins aux aspects 1:1/16:9/9:16 verifies avant activation du backend.
aperture>=0, focaldist>0, defaults loader aperture=0/focaldist=1/FOV=45.
Pinhole a aperture=0. Convention distante figee : rayon lentille=sqrt(aperture),
rho=sqrt(U*aperture), phi=2*pi*V, offset=rho*(cos(phi)*right+sin(phi)*up),
focalPoint=focaldist*rayDir, origin=position+offset, direction=normalize(focalPoint-offset).
La surface focale de cette equation est spherique, pas un plan a distance axiale constante.
Preserver cette semantique pour le rapprochement et tester points hors axe ; pas f-stop.
Autorite : defaults locaux -> .scene -> overrides CLI/URL explicites -> interaction GUI.
reset scene recharge la camera scene ; resize change uniquement aspect, pas pose/FOV.
Chaque changement invalide accumulation et denoise. Camera legacy des scenes nommees preservee.

## C05 - Lumieres [REQ-006]

Scene .scene autoritaire : pas d'ajout automatique soleil/lumieres MTLX ; fusion seulement
sur option explicite avec IDs/source. Environnement independant, envmapfile=none le desactive.
Reference types quad=0/sphere=1/distant=2 ; local historique point=0/directional=1/spot=2/quad=3.
Mapper par nom vers representation canonique, jamais via cast d'enum. Point/spot locaux
restent extensions distinctes ; la syntaxe .scene v1 n'accepte que quad/sphere/distant.
type obligatoire, valeurs finies. emission RGB lineaire >=0 = radiance pour les area lights,
pas puissance totale ; aucun exposure/sRGB applique aux buffers de scene.
Quad : position coin, u=v1-position, v=v2-position, aire=length(cross(u,v))>0.
Le parcours RectIntersect repris suppose un rectangle : verifier u/v orthogonaux
a 1e-6 relatif, sinon LIGHT_QUAD_NON_ORTHOGONAL avant upload. Pas de quad cisaille
incorrectement accepte comme rectangle ; une extension parallelogramme est hors v1.
Sphere : radius>0, aire=4*pi*radius^2. Sphere vue de l'interieur : strategie uniforme
sur sphere complete et PDF correspondante, ne pas copier l'hypothese externe-only distante.
Distant : position encode une direction vers la source, direction=normalize(position),
vecteur non nul, distance infinie, evenement delta ; pas d'attenuation 1/r^2.
Les routines distantes multiplient emission par numOfLights : adaptation locale exprime
plutot pSelect=1/N et divise une seule fois le poids par pSelect. Pas de double facteur N.
Quad/sphere : PDF directionnelle = pdfArea*distance^2/abs(dot(normal,-direction)),
avec visibilite et sidedness coherentes entre NEE et hit emetteur. MIS avec pSelect
explicite ; distant/point/spot delta hors concurrence PDF continue. Quad emet cote normal.
Light hit et geometry hit compares par t ; hideemitters masque uniquement camera primaire.
La texture locale mtlxLightsTex contient aussi des lignes de parametres MTLX : ne pas
la reutiliser pour lightsTex RGB reference. Garder les lignes/offsets de parametres locaux
intacts, texture lumiere reference distincte et decodeur canonique vers l'integrateur.

## C06 - Loader et directives [REQ-004, REQ-007]

scene-directives.json classe chaque token du loader inspecte : supported signifie
semantique reprise, adapted conversion explicite, rejected erreur avant chargement.
Aucun de ces labels ne signifie implemente. Options rejetees atlas/RR/volumeMIS/
mollification/uniformlight/sssmode ne doivent pas alterer l'integrateur local.
tilewidth/tileheight : entiers positifs conserves en metadata avec avertissement
SCENE_OPTION_NO_RUNTIME_EFFECT ; ils n'activent pas de rendu tuile dans le viewer.
Dans material, adapted signifie donnees parsees mais non converties automatiquement
en BSDF ; binding local explicite obligatoire si aucune source .mtlx n'existe.
specular est rejete : present dans disney-gold mais non lu par le loader distant.
Pour un temoin non-MTLX, utiliser le fichier distant tel quel ; pour le loader local,
creer une fixture distincte conforme, ne pas supprimer silencieusement ce champ.
material_type=materialx exige exactement document OU inline. Toute source MTLX implique
le generateur local ; document+inline, source vide, echec generation -> erreur nommee.
Blocs material repetables avec noms uniques ; camera/renderer uniques. References
resolues apres parsing, ordre de declaration libre. Overrides object/glob case-insensitive,
plusieurs matches permis, zero match en erreur ; ordre fichier, dernier match prioritaire.
Objet scene atomique : parse -> validation -> ressources -> dispatch -> BVH -> upload -> publish.
Annulation via revision ; aucun shader/scene stale repris si erreur.
URLs : new URL(resource, ownerUrl), base .scene pour meshes/envmap, base .mtlx pour images,
base .gltf pour buffers/textures ; permettre HTTP(S)/same-origin et chemins publics,
pas de chemin disque arbitraire .scene, execution, file: ou javascript:.
BOM/CRLF, whitespace, chaines quotees, commentaires # hors chaine, accolades de bloc
sur lignes propres ; inline XML traite comme texte opaque jusqu'au terminator dedie.
Directive inconnue, doublon scalaire, arite invalide, NaN/Inf, ref inconnue -> erreur
avec URL/ligne/bloc/nom/token. Pas de fallback a un materiau ou type lumiere par defaut.

## C07 - Denoiser [REQ-001, REQ-008]

Adapter le bundle distant uniquement ; backend WebGL sur canvas/contexte dedie,
entree Float32Array RGBA a la resolution de rendu, ordre bottom-up lu par render target.
Uniformiser l'orientation avant/apres API et garder alpha original. Input = moyenne
accumulee en radiance lineaire, avant exposition/tonemapping ; hdr=true, srgb=false.
Le modele selectionne doit etre HDR color-only compatible ; pas de buffers normals/albedo
inventes pour MTLX. Refuser modele manquant/incompatible, pas basculer au modele LDR.
Ne pas ecreter >1. NaN/Inf en erreur diagnostiquee pour les tests ; viewer conserve raw.
Output float finie, meme taille ; tonemapping/exposition une seule fois en presentation.
Snapshot revision/SPP/dimensions immuable, verrou execution, abort et rejet callback stale,
dispose inputs/tensors/listeners. Output jamais reinjectee dans accumulation.
Viewer en echec : raw+diagnostic ; CLI denoise demande en echec : exit non nul.
Poids/URLs/notices doivent etre identifies et servis localement avant T029 ; pas de
telechargement automatique pendant T002, pas d'executable OIDN ou requete CDN requise.
Inventaire source : Weights.url par defaut https://cdn.jsdelivr.net/npm/denoiser/tzas,
sans version verrouillee ; aucun .tza dans src/external/denoiser/. L'API permet weightsUrl.
Selection figee : filterType=rt, quality=fast, hdr=true, srgb=false, color-only ->
rt_hdr_small.tza ; chemin de publication public/denoiser/tzas, URL runtime construite
avec la base Vite (pas la chaine public/ envoyee au navigateur). Desactiver la valeur
CDN avant le premier execute et gerer le singleton Weights sans URLs perimees.
Origine/version/hash/licence des poids sont relevees ci-dessous ; conserver leur licence
et les notices applicables lors de la copie au jalon denoiser. La presence de l'API
HDR ne prouve pas sa qualite ; scenes HDR et >1 obligatoires au jalon 15.
setInputData appelle une fonction async sans retourner sa promesse dans le bundle
inspecte : adapter ce point de facon explicite pour garantir input-ready avant execute,
avec patch fournisseur minimal documente et test, pas un delai arbitraire.
Le budget initial est une proposition a mesurer a T003/T004 : fixture 256x256,
timeout initialisation 120 s, execution 60 s en SwiftShader, aucun tensor residuel
en croissance apres 10 cycles ; seuil qualite calibre par fixture au jalon 15.

### Provenance des poids verifiee le 2026-10-04

Source fournie par l'utilisateur : D:/WebGL2/Denoiser/packages/denoiser/tzas.
21 fichiers .tza ; rt_hdr_small.tza et rt_ldr_small.tza sont des binaires complets,
pas des pointeurs Git LFS. Conserver le choix HDR ; ne pas remplacer par la variante LDR.
Depot https://github.com/DennisSmolek/Denoiser.git, branche main,
HEAD 48ee97a4f13ce50ed661faac5e87e0e2755dd12c. Worktree modifie : fichiers package.json,
yarn.lock, .yarn/install-state.gz et src/types.ts non suivi dans packages/denoiser.
La version 0.0.11 du package de travail est verifiee avec son hash, pas deduite d'un HEAD propre.

| Fichier | Octets | SHA-256 |
| --- | --- | --- |
| rt_hdr_small.tza | 634568 | c9171947f2bceb4367725b7a0d5b4e0d663ac44108386af42f1b49e4361952e7 |
| rt_ldr_small.tza | 634568 | d50ad6ca693ec8f2bdfac5d4657c4cb7c0763b20a9768e66f0402a00046b704c |
| tzas/LICENSE.txt | 11560 | 3ddf9be5c28fe27dad143a5dc76eea25222ad1dd68934a047064e56ed2fa40c5 |

Licence des poids : Apache-2.0, notice presente dans tzas/LICENSE.txt. Licence du
paquet : MIT, Dennis Smolek 2024, presente dans D:/WebGL2/Denoiser/LICENSE.
Archive npm denoiser@0.0.11 inspectee dans le dossier temporaire, sans installation :
https://registry.npmjs.org/denoiser/-/denoiser-0.0.11.tgz.
Son integrite SHA-512 correspond a la valeur npm figee dans scene-directives.json.
Les deux hashes de poids locaux sont identiques a ceux de package/tzas/ dans l'archive.
Le dossier chrome-extension-shadertoy/tzas ne contient que le poids LDR identique.

Le bundle packages/denoiser/dist/index.mjs est identique au bundle npm (SHA-256
e29a88880da7f5f1f5d5578c82aaa6df754e511d62e5da9f5c263ededacc67c5), mais different du
bundle distant inspecte en T001 (0362f90554f25660721233c26d975a8b47a1c7e0f929c8be3038bb7ca644274d).
Ne pas lui substituer automatiquement le bundle publie : les adaptations du bundle
distant et les notices tierces restent a inventorier. L'executable OIDN sera retire,
mais ces poids proviennent du denoiser OIDN/TensorFlow.js, ce qui n'est pas contradictoire.
Lors de publication, fournir la licence Apache, conserver les notices applicables
et signaler les modifications. Aucun poids n'a ete installe ou publie dans le viewer.

## C08 - Gates et preuves [REQ-007]

Pas de runtime modifie pendant T002. Verification statique exige la couverture de tous
les tokens reconnus dans sceneLoader, schemas de classement sans ambiguite, exclusion
du generateur distant et maintien des REQ-001..008. T001 hashes reste prerequis.
Les oracles de rendu restent a executer aux jalons prevus, pas marques PASS par ces docs.
Licences : package distant MIT sans licence racine globale, notice OpenPBR MIT et
notice GLSL Asif Ali MIT observees ; autorisation/provenance TS/assets et licences
completes du bundle non prouvees. Poids HDR/LDR : provenance et licence verifiees
ci-dessus. Documenter les droits et conserver les notices applicables avant redistribution.
Pas d'autorisation inventee par ce contrat. Contrats techniques et inventaire de ressources
requis sont rediges. Cloture du jalon 0 sur decision explicite de l'utilisateur le
2026-10-04 ; reserves de provenance conservees en suivi non bloquant pour T003.
Cette decision de projet ne transforme pas les preuves encore ouvertes en droits verifies.

## Verification et statut

Commande depuis la racine du viewer :

```powershell
node specs/005-mtlx-reference-alignment/validate-t002.mjs
```

Le controle inclut T001, classement des 80 tokens par bloc, trois fixtures non-MTLX
avec hashes et presence de leurs maillages, equations camera tile/preview et selection
du modele HDR. Ce sont des assertions statiques, pas des tests du futur loader/rendu.

Decisions de port : C01 -> T013..T016, C02/C03 -> T007..T018,
C04 -> T023/T024, C05 -> T025/T026, C06 -> T019..T022/T027,
C07 -> T029..T032, C08 -> tous les controles du plan.

Jalon 0 : COMPLETED. Cloture demandee explicitement par l'utilisateur le 2026-10-04.
Suivi non bloquant : provenance/attributions des adaptations TS et assets,
inventaire complet des notices et modifications du bundle denoiser.
Filiation BVH C++ RadeonRays et licence MIT AMD : bvh-provenance.json et
validate-bvh-provenance.mjs ; ces preuves ne remplacent pas les tests algorithmiques.
Origine, version, SHA-256 et licence des poids sont desormais verifies. L'archive npm a ete
telechargee dans le dossier temporaire uniquement ; aucun poids deploye dans le viewer.
T003 peut etre preparee ; elle n'est pas executee par cette cloture. Les gates des
jalons suivants restent obligatoires. Aucun runtime modifie par ce changement de statut.