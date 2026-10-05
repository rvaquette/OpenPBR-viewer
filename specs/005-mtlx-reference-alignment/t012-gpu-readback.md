# T012 - Readback GPU des textures BVH

Date : 2026-10-05. [REQ-002, REQ-003, REQ-007], Plan:5.

## Sonde

`tools/mtlx-reference-alignment/gpu-readback-probe.mjs` construit une fixture
CPU de 12 triangles et 3 instances, puis passe les cinq buffers de
`packReferenceScene` dans des textures WebGL2 RGBA32F/RGBA32I de test. La largeur
de packing est limitee a 8 texels pour forcer le franchissement de ligne dans
chaque buffer.

Un shader ESSL 3.00 emploie `texelFetch` sur `sampler2D` ou `isampler2D`. Il
encode les bits des quatre composantes par texel dans RGBA8 ; `readPixels` relit
les octets, qui sont compares exactement au tableau CPU (Float32 ou Int32).
La comparaison couvre tous les texels alloues, y compris la fin logique, les
lignes supplementaires et le padding. Elle verifie ainsi l'orientation y, le
mapping de lignes, les valeurs w nulles de l'ABI logique RGB et les matrices.
L'encoding RGBA8 evite de dependre de la prise en charge du readback RGBA32F.

La sonde verifie aussi les filtres Nearest/ClampToEdge, le sampler entier,
l'absence de flipY et de conversion de couleur, l'acceptation de l'ID float32
maximal 2^24-1 et le rejet au-dela, le budget des cinq samplers et le refus d'un
buffer excedant MAX_TEXTURE_SIZE.

## Resultats

- Chrome / ANGLE Vulkan SwiftShader, contexte WebGL2 ; MAX_TEXTURE_SIZE observe
  8192 et MAX_TEXTURE_IMAGE_UNITS 32. La fixture a limite le packing a 8.
- 152 texels physiques relus bit a bit sur les cinq buffers ; chaque texture
  franchit au moins une ligne. Sampler entier `isampler2D` valide.
- Padding zero, formats RGBA32F/RGBA32I, matrices de trois instances et IDs
  verifies ; flipY=false, colorspace conversion NONE ; zero erreur GL.
- Rapport detaille : `artifacts/mtlx-reference-alignment/t012-gpu-readback.json`.
- `npm test` : 55/55 PASS. `npm run build` : PASS ; avertissements Vite CJS et
  taille du chunk preexistants.

La sonde relit les formats physiques remplis depuis le packing CPU ; T011 a
independamment verifie l'initialisation des DataTexture par `renderer.initTexture`.
Ce n'est ni une integration au renderer, ni un parcours BVH/shading, ni une
validation Adreno. Aucun rendu MTLX distant n'est execute. Backend de production
Three.js, `referenceReady=false` ; le jalon 5 de packing/readback est complet.