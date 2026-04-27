---
name: test-engine
description: Use when writing tests, improving coverage, designing E2E flows, or reducing flaky behavior in automation. Avoid when the task is pure refactoring with no testing component.
title: Test Engine
version: 0.2.0
summary: Design resilient test strategies and practical unit, integration, E2E, and Playwright coverage improvements.
---

# Test Engine

## Purpose

Design and improve test strategy, coverage, edge-case validation, unit and integration tests, E2E flows, and Playwright-based automation.

## Use When

- Writing tests for new or changed behavior.
- Reviewing test quality or coverage gaps.
- Designing E2E or Playwright workflows.
- Reducing flaky or brittle tests.
- Improving edge-case validation.

## Avoid When

- The task is pure refactoring without tests.
- The user only wants documentation.

## Workflow

1. Map the behavior, risk, and test boundaries that matter; if behavior is ambiguous, ask one question before writing tests.
2. Choose the lowest-cost test level that proves the behavior.
3. Add meaningful happy-path, edge-case, and failure coverage.
4. Keep E2E tests stable by controlling timing, data, and selectors; skip E2E when the test environment is unavailable and note the gap.
5. Report gaps, cases, and remaining risk.

## Output Contract

Default:

```text
test-plan:
1. ...

coverage-gaps:
- ...

cases:
- given/when/then

risk:
- ...
```

## Error Handling

1. Local: If target behavior is unclear, ask one question before writing tests.
2. Flow: Skip E2E tests when the test environment is unavailable; note the coverage gap explicitly.
3. Recovery: Revert to the last stable test suite state if new tests fail unexpectedly.

## References

- See `references/workflow.md` for the detailed workflow.
- See `references/examples.md` for sample test plans.

## Rules

- `rules/_sections.md`
- `rules/behavior-over-implementation.md`
- `rules/meaningful-coverage.md`
- `rules/edge-cases.md`
- `rules/e2e-stability.md`
- `rules/flaky-test-reduction.md`
