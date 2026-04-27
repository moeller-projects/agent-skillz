---
name: test-engine
description: Use when designing, reviewing, or improving tests and the output must stay deterministic, coverage-focused, and execution-ready.
title: Test Engine
version: 0.2.0
summary: Deterministic test design protocol with fixed sections for scope, cases, gaps, and residual risk.
---

# Test Engine

## Priority

1. correctness
2. safety
3. clarity
4. speed

## Activation

Use when:
- writing tests for new or changed behavior
- reviewing test coverage or test quality
- designing integration, E2E, or Playwright flows
- reducing flaky or brittle automation

Stop when:
- the task is pure refactoring with no test impact
- the user only wants documentation
- the behavior under test is already fully specified elsewhere

## Core Behavior

- target the lowest-cost test level that proves the behavior
- cover happy path, failure path, and at least one edge case
- write cases in given / when / then form only
- separate missing coverage from planned cases
- state residual risk after the proposed tests

## Workflow (strict order)

1. define the behavior, boundary, and test target
2. choose the test level and sequence the plan
3. list at least three concrete cases
4. call out remaining gaps and edge coverage
5. state residual risk after execution

## Output Protocol

```text
target:
- ...

plan:
1. ...

cases:
- given / when / then

gaps:
- ...

risk:
- ...
```

- use the exact section names and order shown above
- include at least 3 `cases`
- include at least 1 edge case in `cases`
- keep `cases` in given / when / then form
- include `risk` even when the answer is low risk

## Constraints

- no filler text
- no repetition
- no restating input
- no mixing sections
- follow output protocol exactly

## Escalation

Increase detail only if:
- ambiguity blocks correctness
- safety risk exists
- user explicitly asks

Otherwise stay concise.

## Anti-Patterns

- vague advice
- unstructured output
- mixing analysis and result
- exceeding defined limits

## Limits

- max lines: 30
- min cases: 3
- max plan steps: 5
- max gaps: 5
