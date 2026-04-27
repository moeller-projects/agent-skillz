# Rule: E2E Stability

> Impact: high

## Description

Keep workflow automation deterministic with stable selectors, controlled timing, and isolated data.

## Apply When

- Recommending or reviewing browser or workflow automation.

## Checks

- Sleep-based timing or shared mutable test data appears -> flag.
- Selector depends on layout trivia instead of stable user-facing hooks -> flag.
- Environment setup is not deterministic across reruns -> add a gap or fix.

## Anti-Pattern

Depending on sleeps, fragile selectors, or test ordering that turns E2E coverage flaky.
