---
name: code-quality-engine
description: Use when reviewing, refactoring, or modernizing code for correctness, maintainability, or evidence-backed performance work. Do not use when the request is test quality or coverage review, documentation, or infrastructure work.
allowed-tools:
  - read_file
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

## Validation Checklist

- [ ] Findings sorted by severity: critical → high → medium → low.
- [ ] Each finding has file, line, issue, and exact fix.
- [ ] Patch steps are in safe application order.
- [ ] Performance changes included only when profiling data exists.
- [ ] Residual risks listed.

See `tests/validation-checklist.md` for the full checklist.

## Assets

- `assets/templates/output.md` — concrete output template
- `assets/examples/happy-path.md` — mixed bug/cleanup scenario
- `assets/examples/edge-case.md` — performance request without profiling data
- `scripts/validate-output.sh` — validates output format

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
