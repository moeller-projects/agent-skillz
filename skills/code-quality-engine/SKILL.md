---
name: code-quality-engine
description: Use when reviewing, refactoring, optimizing, or modernizing code while keeping changes as small and safe as possible.
title: Code Quality Engine
version: 0.1.0
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

1. Confirm current behavior, constraints, and failure risks.
2. Find the highest-value correctness and maintainability issues first.
3. Prefer the smallest safe change that improves the code materially.
4. Treat performance work as evidence-driven, not speculative.
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

## Rules

- `rules/_sections.md`
- `rules/correctness-first.md`
- `rules/minimal-mutation.md`
- `rules/complexity-reduction.md`
- `rules/performance-when-real.md`
- `rules/legacy-safety.md`
