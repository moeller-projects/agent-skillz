# Rule: Performance When Real

> Impact: medium

## Description

Treat performance work as evidence-driven triage, not speculative cleanup.

## Apply When

- Performance is raised as a goal or a likely problem.

## Checks

- No bottleneck, symptom, or metric named -> flag speculative advice.
- Recommendation trades readability for micro-optimization with no evidence -> drop it.
- Performance finding lacks validation steps in `tests` -> add them.

## Anti-Pattern

Suggesting micro-optimizations because they sound fast, even though no real performance problem is established.
