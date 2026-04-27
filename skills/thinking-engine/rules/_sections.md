# Rule: Standard Sections

> Impact: medium

## Description

Require the exact section order for deterministic decision output so the result can be scanned and executed without interpretation.

## Apply When

- A planning or critique response is requested.

## Checks

- `problem` missing or not first -> flag.
- `assumptions`, `options`, `decision`, `risks`, or `next` missing -> flag.
- `options` not numbered or `next` not numbered -> flag.
- `decision` missing -> block completion.

## Anti-Pattern

Using free-form analysis that forces the reader to infer the problem, recommendation, or next action.
