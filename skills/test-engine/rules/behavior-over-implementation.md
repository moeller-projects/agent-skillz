# Rule: Behavior Over Implementation

> Impact: critical

## Description

Prefer tests that prove observable behavior instead of private implementation details.

## Apply When

- Designing or reviewing automated tests.

## Checks

- Assertion targets a private helper or internal call count with no contract value -> flag.
- Case does not describe externally visible output, state, or side effect -> rewrite.
- Mocking replaces the behavior under test instead of isolating a boundary -> flag.

## Anti-Pattern

Locking tests to internals that make safe refactoring impossible.
