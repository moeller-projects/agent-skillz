# Rule: Convention Extraction

> Impact: medium

## Description

Capture conventions only when they are supported by repeated repository evidence and affect future changes.

## Apply When

- Contributors need guidance on how to work within the repository.

## Checks

- Convention appears only once or is guessed -> do not report it.
- Convention has no implementation impact -> drop it.
- `conventions` omits build, test, naming, or workflow expectations that recur across the repo -> flag.

## Anti-Pattern

Inventing style or workflow rules that are not demonstrated by the repository.
