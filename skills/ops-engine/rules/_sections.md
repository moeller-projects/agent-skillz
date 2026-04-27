# Rule: Standard Sections

> Impact: medium

## Description

Keep operational output deterministic so execution, rollback, and security review can happen fast.

## Apply When

- Producing an infrastructure, release, or threat-model recommendation.

## Checks

- `risk`, `plan`, `checks`, `rollback`, or `security` missing -> flag.
- `risk` has no entries -> block completion.
- `plan` is not numbered or `rollback` is empty -> flag.
- Security notes are mixed into `checks` instead of `security` -> split them.

## Anti-Pattern

Recommending an ops change with no rollback path or clear validation criteria.
