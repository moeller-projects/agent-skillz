---
name: test-engine
description: Use when writing tests, improving coverage, designing E2E flows, or reducing flaky behavior in automation.
title: Test Engine
version: 0.1.0
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

1. Map the behavior, risk, and test boundaries that matter.
2. Choose the lowest-cost test level that proves the behavior.
3. Add meaningful happy-path, edge-case, and failure coverage.
4. Keep E2E tests stable by controlling timing, data, and selectors.
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

## Rules

- `rules/_sections.md`
- `rules/behavior-over-implementation.md`
- `rules/meaningful-coverage.md`
- `rules/edge-cases.md`
- `rules/e2e-stability.md`
- `rules/flaky-test-reduction.md`
