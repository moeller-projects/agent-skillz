# Rule: Standard Sections

> Impact: medium

## Description

Keep test planning deterministic so the execution target, cases, and remaining risk are obvious.

## Apply When

- Producing a testing recommendation or review.

## Checks

- `target`, `plan`, `cases`, `gaps`, or `risk` missing -> flag.
- Fewer than 3 `cases` -> block completion.
- `cases` not written as given / when / then -> rewrite.
- No edge case included -> flag.

## Anti-Pattern

Providing vague test ideas with no structure, no coverage boundary, and no execution order.
