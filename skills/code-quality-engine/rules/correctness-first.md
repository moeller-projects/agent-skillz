# Rule: Correctness First

> Impact: critical

## Description

Prioritize defects that can break behavior, data, or safety before readability or cleanup suggestions.

## Apply When

- Reviewing or refactoring production code.

## Checks

- Style-only findings appear before correctness or safety issues -> reorder or drop.
- A fix changes behavior without acknowledging the risk -> flag.
- Security-adjacent bug treated as minor -> raise severity.

## Anti-Pattern

Focusing on aesthetics while real defects remain unresolved.
