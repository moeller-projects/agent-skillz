# Rule: Standard Sections

> Impact: medium

## Description

Keep repository mapping output deterministic and reusable for onboarding or planning.

## Apply When

- Producing an onboarding or architecture summary.

## Checks

- `map`, `entry`, `flow`, `conventions`, `hotspots`, or `next` missing -> flag.
- Any section exceeds 10 entries -> trim.
- Raw file dump appears without role or impact -> rewrite.
- `next` lacks an action-oriented follow-up -> flag.

## Anti-Pattern

Dumping files and directories without turning them into a usable operating model.
