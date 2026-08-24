# Legacy comparison workflow

This folder is reserved for manual legacy-vs-generated comparison artifacts.

## Rules
- Do not use these artifacts in the production substitution pipeline.
- Keep legacy captures and notes here when reviewing visual differences manually.
- Classify manual findings with one category per material: none, energy, hue, detail, or mixed.

## Production boundary
- Runtime substitution in pathtracer mode must use generated MaterialX shading only.
- Legacy pathtracer mode is an opt-in manual comparison mode enabled with `legacy_comparison=true`.
