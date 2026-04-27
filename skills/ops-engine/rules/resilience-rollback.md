# Rule: Resilience and Rollback

> Impact: critical

## Description

Every operational plan must define failure handling, rollback triggers, and recovery checks before execution.

## Apply When

- The change can affect availability, data integrity, or runtime behavior.

## Checks

- `rollback` does not contain executable steps -> flag.
- Stop condition or rollback trigger is missing -> flag.
- Recovery validation after rollback is omitted from `checks` or `rollback` -> flag.

## Anti-Pattern

Approving an ops change because it should work while having no reliable path back.
