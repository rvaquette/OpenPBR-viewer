# T011 - Packing et upload des textures BVH

Date : 2026-10-05. [REQ-002, REQ-003, REQ-007], Plan:5.

## Implementation

`src/bvh/referenceGpuAdapter.js` prepare les cinq buffers BVH, indices de
triangles, vertices/U, normales/V et transforms column-major. Seuls les noeuds
actifs sont serialises ; le stockage de reserve du traducteur est exclu.
`topBVHIndex`, le nombre de noeuds et le nombre d'instances sont fournis en uniforms.
Les offsets logiques globaux et meshRanges sont conserves.

Three.js r159 ne fournit ni RGBFormat ni RGBIntegerFormat utilisables pour cet
upload. Decision utilisateur explicite du 2026-10-05 : stockage physique RGBA32F
et RGBA32I, sans changer l'ABI logique RGB de la reference. Pour BVH/indices,
chaque triplet occupe un texel RGBA avec w=0 ; les lectures .xyz et les adresses
de texels restent identiques. Surcout de 1/3 pour ces donnees RGB, hors padding.
Vertices, normales et matrices restent naturellement RGBA.

Dimensions : width=min(4096,MAX_TEXTURE_SIZE,max(1,texelCount)), height arrondi
au dessus. Padding zero ; buffers vides en sentinelles 1x1 avec comptes zero.
Int32 pour les indices, Float32 pour les autres buffers. IDs float exacts limites
a 2^24-1 ; indices vertices controles, bounds finies et ordonnees, tags et
partitions BLAS/TLAS controles, racine/materiau TLAS conformes a chaque instance.

Les cinq samplers plus reservedTextureUnits (obligatoire) doivent tenir dans
MAX_TEXTURE_IMAGE_UNITS. maxBufferBytes permet une limite memoire aggregate.
Depassement de taille, budget ou precision : erreur explicite avant upload.
Textures Nearest/ClampToEdge, sans mipmaps, flipY ou conversion de couleur.
L'upload utilise renderer.initTexture ; dispose est idempotent et les ressources
sont liberees si l'initialisation leve une exception.

## Validation

- `npm test` : 55/55 PASS, dont 6 tests de l'adaptateur GPU.
- Packing relu cote CPU : donnees RGB/RGBA, matrices, normales, passage de ligne,
  padding, sentinelles vides, erreurs de capacite et donnees invalides.
- Creation/disposal DataTexture et echec partiel d'upload controles par mock.
- `node tools/mtlx-reference-alignment/gpu-upload-smoke.mjs` : PASS Chrome/SwiftShader
  WebGL2, cinq textures initialisees pour une scene pleine et une scene vide,
  aucune erreur GL. Rapport : artifacts/mtlx-reference-alignment/t011-upload-smoke.json.
- `npm run build` : PASS ; avertissements Vite CJS/chunk existants conserves.

Le smoke bundle isole importe les modules locaux et Three.js, pas le renderer
distant. Aucune relecture GPU, shader de parcours, comparaison de rayons ou
validation Adreno n'est revendiquee. T012 reste necessaire pour verifier les
valeurs effectivement fetchables et terminer le jalon 5.

main.js et le GLSL de production restent inchanges ; backend actif Three.js,
referenceReady=false. Aucun rendu MTLX distant execute. Tangentes et attributs
additionnels restent dans les sidecars CPU, pas dans ces cinq textures de base.