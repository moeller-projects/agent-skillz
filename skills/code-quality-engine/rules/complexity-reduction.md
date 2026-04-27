# Rule: Complexity Reduction

> Impact: high

## Description

Reduce branching, duplication, hidden coupling, and incidental complexity when it improves comprehension or change safety.

## Apply When

- Code is hard to reason about or expensive to modify.

## Checks

- Call out the specific complexity source.
- Prefer simplifications that remove future maintenance cost.

## Anti-Pattern

Introducing abstractions that make the code more indirect without solving a real complexity problem.
