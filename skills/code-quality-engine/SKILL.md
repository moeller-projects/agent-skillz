---
name: code-quality-engine
description: Use when reviewing, refactoring, optimizing, or modernizing code. Avoid when only documentation, tests, or infrastructure work is requested.
title: Code Quality Engine
version: 0.2.0
summary: Improve correctness, readability, maintainability, performance, and legacy modernization with minimal mutation.
---

# Code Quality Engine

## Purpose

Improve code correctness, readability, maintainability, performance, and modernization safety with the smallest reasonable change set.

## Use When

- Reviewing code for quality or safety.
- Refactoring for clarity or maintainability.
- Optimizing performance with real evidence.
- Reducing complexity in fragile areas.
- Modernizing legacy code with minimal mutation.

## Avoid When

- Only documentation is requested.
- Test design is the primary task.
- Infrastructure or deployment is the primary task.

## Workflow

1. Confirm current behavior, constraints, and failure risks; if behavior is unclear, ask one question before proceeding.
2. Find the highest-value correctness and maintainability issues first.
3. Prefer the smallest safe change; when the change touches critical paths, verify behavior before applying.
4. Treat performance work as evidence-driven; skip it when no profiling data exists.
5. Present findings, patch order, and residual risk.

## Output Contract

Default:

```text
findings:
- [severity] file:line — issue
  why:
  fix:

patch-plan:
1. ...

risk:
- ...
```

## Error Handling

1. Local: If evidence for a finding is insufficient, note the gap and move to the next issue.
2. Flow: Skip performance changes when no profiling data exists; abort if the proposed patch surface is unsafe.
3. Recovery: Revert suggestions if applying a patch fails tests or introduces new failures.

## References

- See `references/workflow.md` for the detailed workflow.
- See `references/examples.md` for sample findings and patch plans.

## Rules

- `rules/_sections.md`
- `rules/correctness-first.md`
- `rules/minimal-mutation.md`
- `rules/complexity-reduction.md`
- `rules/performance-when-real.md`
- `rules/legacy-safety.md`
