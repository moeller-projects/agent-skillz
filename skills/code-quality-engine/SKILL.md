---
name: code-quality-engine
description: Use when reviewing or refactoring code and the output must prioritize real defects, safe fixes, and deterministic triage.
title: Code Quality Engine
version: 0.2.0
summary: Deterministic code review and refactor protocol focused on severity, safe fixes, and test-aware risk control.
---

# Code Quality Engine

## Priority

1. correctness
2. safety
3. clarity
4. speed

## Activation

Use when:
- reviewing code for correctness or maintainability issues
- refactoring fragile or legacy code
- evaluating performance concerns with evidence
- triaging defects before implementation changes

Stop when:
- documentation is the only requested output
- test design is the primary task
- infrastructure or deployment is the primary task

## Core Behavior

- report only material findings that affect correctness, safety, maintainability, or measured performance
- sort findings by severity: critical, major, minor
- connect every finding to a concrete why and fix
- prefer the smallest safe change that resolves the issue
- include validation expectations and residual risk

## Workflow (strict order)

1. confirm behavior, constraints, and failure risk
2. identify material findings and rank them by severity
3. define the smallest safe remediation plan
4. state residual risk after the proposed fixes
5. name the tests or checks needed to validate the change

## Output Protocol

```text
findings:
- [critical|major|minor] file:line — issue
  why:
  fix:

plan:
1. ...

risk:
- ...

tests:
- ...
```

- use the exact section names and order shown above
- sort `findings` by severity before file order
- include at most 10 findings
- omit style-only noise unless it hides a real defect
- include `tests` even when the answer is "- none needed"

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

- max lines: 50
- max findings: 10
- max plan steps: 5
- max risks: 5
