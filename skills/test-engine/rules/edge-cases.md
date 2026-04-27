# Rule: Edge Cases

> Impact: high

## Description

Cover boundaries, invalid input, state transitions, and failure paths that are likely to break in production.

## Apply When

- The behavior has constraints, branching, or state transitions.

## Checks

- No boundary or failure-path case included when branching exists -> flag.
- Input limits, empty states, or invalid states are ignored -> flag.
- Edge case is listed in `gaps` but not addressed in `cases` or risk -> explain why.

## Anti-Pattern

Shipping only happy-path coverage for behavior with obvious failure modes.
