# Matrice de support WebGPU

## Cible initiale

| Navigateur | Systeme | WebGPU | Statut initial |
|---|---|---|---|
| Chrome stable | Windows 10/11 | Requis | Cible de validation |
| Microsoft Edge stable | Windows 10/11 | Requis | Cible de validation |
| Autre navigateur ou WebGPU desactive | Tout | Indisponible | WebGL2 explicite |

Le backend `webgl` est le defaut. `?renderer_backend=webgpu` exprime une demande WebGPU; avant la phase 2, le diagnostic declare cette implementation comme `planned` et le rendu actif reste WebGL. Une fois l'hote WebGPU livre, une indisponibilite de l'adaptateur ou du device doit produire une erreur visible et actionnable, sans bascule silencieuse.

## Prerequis de validation

- WebGPU actif dans le navigateur cible et pilote graphique fonctionnel.
- `navigator.gpu` disponible et `requestAdapter()` retourne un adaptateur.
- Les captures WebGL de reference utilisent `--gpu=false` (SwiftShader); cela ne valide pas WebGPU.
- Les captures WebGPU utilisent le navigateur et le GPU cibles, avec les metadonnees adaptateur/device enregistrees dans leur rapport.