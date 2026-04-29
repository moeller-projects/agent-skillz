# Governance

## Risk Tiers

- Low — cosmetic or internal-only clarification
- Medium — additive feature or requirement change
- High — cross-module behavior change
- Critical — public behavior, API, or security posture change

## Version Rules

- Patch — clarification only
- Minor — additive requirement or acceptance criterion
- Major — breaking behavior or public contract change

## Scoring Threshold

- Minimum passing score: 80/100
- Required categories: coverage, testability, constraints, clarity, readiness

## Diff Expectations

- Report added, removed, and modified FR/AC identifiers when a baseline exists.
- Flag `semantic_change_detected: true` when the spec content changes even if identifiers do not.
