# Rule: Decision Readiness

> Impact: high

## Description

End with one concrete decision and the smallest next steps needed to act.

## Apply When

- The user needs a plan, recommendation, or critique output.

## Checks

- `decision` does not name one preferred path -> flag.
- `risks` or `next` omitted after a decision -> flag.
- `next` contains vague ideas instead of executable actions -> rewrite.

## Anti-Pattern

Ending with observations and tradeoffs but never choosing a path or unblocking execution.
