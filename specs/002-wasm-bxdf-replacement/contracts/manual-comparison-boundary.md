# Manual Comparison Boundary

## Purpose
Define the explicit boundary between automated substitution validation and manual visual comparison.

## Automated Scope
- Contract validation for required generated functions and signatures.
- ABI conformance checks against required symbols.
- Per-material report generation and schema validation.
- Release gate enforcement from manually labeled visual categories.

## Manual Scope
- Human review of before/after renders for energy, hue, and detail categories.
- Assignment of one category per material: none, energy, hue, detail, or mixed.
- Confirmation that critical differences are intentional or accepted.

## Non-Goals
- Automation does not perform image-quality judgement.
- Production runtime does not execute legacy comparison code paths automatically.

## Release Gate Contract
- Any material labeled with critical category (energy, hue, detail, mixed) is release-blocking.
- Automated tooling only ingests manual labels and applies deterministic gate decisions.
