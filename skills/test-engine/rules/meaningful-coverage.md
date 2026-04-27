# Rule: Meaningful Coverage

> Impact: high

## Description

Add tests where they materially reduce product or regression risk.

## Apply When

- Coverage gaps or missing tests are part of the task.

## Checks

- Proposed case has no stated reason or risk coverage -> flag.
- Low-value percentage chasing is prioritized ahead of critical path coverage -> reorder.
- `gaps` omits a known untested high-risk path -> flag.

## Anti-Pattern

Adding shallow tests to improve a metric while the important behavior stays unverified.
