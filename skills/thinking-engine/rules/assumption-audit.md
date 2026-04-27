# Rule: Assumption Audit

> Impact: critical

## Description

Expose the assumptions that can change the decision before locking in a recommendation.

## Apply When

- The task is ambiguous, strategic, or likely to hide unknowns.

## Checks

- More than 5 assumptions -> trim to the material ones.
- Facts mixed into `assumptions` -> separate them.
- Constraint, dependency, or missing input that changes the decision is omitted -> flag.

## Anti-Pattern

Treating guesses as settled facts and making the decision look more certain than it is.
