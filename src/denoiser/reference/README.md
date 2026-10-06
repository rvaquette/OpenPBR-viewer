# Vendored denoiser

- Package: `denoiser@0.0.11`, MIT; original bundle SHA-256 before local patch:
  `e29a88880da7f5f1f5d5578c82aaa6df754e511d62e5da9f5c263ededacc67c5`.
- Local bundle: `denoiser.mjs`; its only source change is making
  `setInputData()` async and awaiting `handleInputTensors()` so callers can wait
  for the RGBA split/alpha setup before `execute()`.
- Selected weights: `public/denoiser/tzas/rt_hdr_small.tza`, 634568 bytes,
  SHA-256 `c9171947f2bceb4367725b7a0d5b4e0d663ac44108386af42f1b49e4361952e7`.
  The adjacent `LICENSE.txt` is Apache-2.0 and covers the weights; `LICENSE`
  here is the package's MIT license.
- Runtime code sets `weightsUrl` to the local Vite-served `public/denoiser/tzas`
  directory. The bundle's jsDelivr default is never used by the viewer.