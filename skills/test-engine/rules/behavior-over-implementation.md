# Rule: Behavior Over Implementation

> Impact: critical

## Description

Prefer tests that verify externally visible behavior and contracts instead of internal implementation details that make tests brittle.

## Apply When

- Designing or reviewing automated tests.

## Checks

- Assertions focus on outputs, state changes, or user-visible results.
- Avoid mocking or asserting internals unless they are the contract.

## Anti-Pattern

Locking tests to private method calls, DOM structure trivia, or incidental sequencing.
