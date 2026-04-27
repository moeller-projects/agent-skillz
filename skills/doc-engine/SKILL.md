---
name: doc-engine
description: Use when planning or reviewing documentation and the output must stay structured, concise, and directly usable by the target reader.
title: Doc Engine
version: 0.2.0
summary: Deterministic documentation protocol with fixed sections for target, structure, content, changes, and gaps.
---

# Doc Engine

## Priority

1. correctness
2. safety
3. clarity
4. speed

## Activation

Use when:
- writing or improving a README
- refining AGENTS.md guidance
- documenting architecture or developer workflows
- creating technical usage or maintenance docs

Stop when:
- the user wants implementation only
- documentation would duplicate obvious code with no action value
- the required structure is already complete and accurate

## Core Behavior

- identify the target reader before drafting content
- define structure before content details
- keep commands, paths, and workflow steps exact
- describe only the content needed for correct action
- separate completed changes from remaining gaps

## Workflow (strict order)

1. define the target reader and document goal
2. propose the structure before content details
3. list required content blocks in priority order
4. summarize the concrete doc changes
5. state remaining gaps or follow-up docs

## Output Protocol

```text
target:
- ...

structure:
- ...

content:
- ...

changes:
- ...

gaps:
- ...
```

- use the exact section names and order shown above
- define `structure` before `content`
- avoid long prose; use short bullets only
- keep every entry tied to reader action or document accuracy
- include `gaps` even when the answer is "- none"

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
- max structure bullets: 10
- max content bullets: 10
- max gaps: 5
