---
name: spec-engine
description: Use when turning requests into specs, validating acceptance criteria, diffing requirement changes, or enforcing spec governance.
title: Spec Engine
version: 0.1.0
summary: Turn requests into structured, version-aware specs with clear requirements, acceptance criteria, and policy gates.
---

# Spec Engine

## Purpose

Extract requirements, create structured specs, validate requirement quality, manage spec diffs, enforce versioning, and produce implementation-ready artifacts.

## Use When

- Creating a spec from user input, tickets, or research.
- Validating requirement quality or acceptance criteria.
- Diffing or versioning spec changes.
- Enforcing policy or governance around requirements.
- Producing implementation-ready artifacts from ambiguous requests.

## Avoid When

- The user only wants code.
- The task has no requirement or spec component.

## Workflow

1. Convert goals, constraints, and context into explicit scope.
2. Write requirements and acceptance criteria that are testable.
3. Check for ambiguity, missing decisions, and policy gaps.
4. Capture diffs or version changes when the spec evolves.
5. Deliver the spec with gates and open questions.

## Output Contract

Default:

```text
spec:
- goal:
- scope:
- requirements:
- acceptance_criteria:

quality_gates:
- ...

open_questions:
- ...
```

## Rules

- `rules/_sections.md`
- `rules/requirement-quality.md`
- `rules/acceptance-criteria.md`
- `rules/diff-versioning.md`
- `rules/policy-gates.md`
