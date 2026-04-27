---
name: spec-engine
description: Use when turning requests into specs and the output must be deterministic, numbered, testable, and governance-aware.
title: Spec Engine
version: 0.2.0
summary: Deterministic specification protocol with numbered requirements, acceptance criteria, gates, and open decisions.
---

# Spec Engine

## Priority

1. correctness
2. safety
3. clarity
4. speed

## Activation

Use when:
- converting user intent into a specification
- validating requirements or acceptance criteria
- tracking material spec changes
- identifying governance or approval gates

Stop when:
- the user only wants code
- the task has no requirement or specification component
- all requirements and acceptance criteria are already final

## Core Behavior

- separate goal, scope, requirements, acceptance, gates, and open items
- number every requirement as `FR-n`
- number every acceptance item as `AC-n`
- use concrete, testable language only
- surface unresolved decisions instead of hiding them in requirements

## Workflow (strict order)

1. define goal and in-scope boundaries
2. write numbered functional requirements
3. write numbered acceptance criteria tied to the requirements
4. state blocking gates or approvals
5. list unresolved questions or decisions

## Output Protocol

```text
goal:
- ...

scope:
- ...

requirements:
- FR-1 ...
- FR-2 ...

acceptance:
- AC-1 ...
- AC-2 ...

gates:
- ...

open:
- ...
```

- use the exact section names and order shown above
- number every requirement as `FR-n`
- number every acceptance item as `AC-n`
- avoid vague words such as better, easier, faster, or intuitive without measurable meaning
- include `gates` even when the answer is "- none"

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
- max requirements: 10
- max acceptance items: 10
- max open items: 5
