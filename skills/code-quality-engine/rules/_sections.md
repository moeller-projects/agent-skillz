# Rule: Standard Sections

> Impact: medium

## Description

Keep review output deterministic so findings, remediation, and validation are triaged in one pass.

## Apply When

- Returning a review, refactor, or modernization assessment.

## Checks

- `findings`, `plan`, `risk`, or `tests` missing -> flag.
- Sections out of order -> reorder.
- `findings` exceeds 10 entries -> trim to material issues only.
- Findings not sorted critical -> major -> minor -> flag.

## Anti-Pattern

Mixing defects, fixes, and risk into prose that cannot be prioritized quickly.
