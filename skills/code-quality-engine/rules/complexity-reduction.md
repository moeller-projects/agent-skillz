# Rule: Complexity Reduction

> Impact: high

## Description

Reduce branching, duplication, and hidden coupling only when it materially lowers maintenance or defect risk.

## Apply When

- Code is hard to reason about or expensive to modify.

## Checks

- Nested depth > 3 with unclear control flow -> flag.
- Duplicate logic across multiple branches or functions -> flag.
- New abstraction adds indirection without removing complexity -> reject.

## Anti-Pattern

Adding abstraction layers that make the code harder to follow without solving a real complexity problem.
