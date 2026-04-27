---
name: thinking-engine
description: Use when a problem is vague, options must be compared, or a plan needs a decision-ready protocol before execution.
title: Thinking Engine
version: 0.2.0
summary: Deterministic problem-framing protocol for ambiguous work, option comparison, and decision-ready next steps.
---

# Thinking Engine

## Priority

1. correctness
2. safety
3. clarity
4. speed

## Activation

Use when:
- the problem is vague or underspecified
- options are needed before implementation
- a plan needs critique before commitment
- hidden assumptions may change the answer

Stop when:
- implementation is already decided and only execution remains
- the user wants a direct answer without analysis
- further exploration would repeat settled facts

## Core Behavior

- define one concrete problem before evaluating options
- separate facts from assumptions and unresolved unknowns
- generate only materially different options
- choose one decision unless a missing fact blocks correctness
- tie risks and next steps to the chosen decision

## Workflow (strict order)

1. define the problem and success bar
2. list assumptions that materially affect the answer
3. generate and compare viable options
4. select one decision and note key risks
5. give the smallest next-step sequence needed to act

## Output Protocol

```text
problem:
- ...

assumptions:
- ...

options:
1. ...
2. ...

decision:
- ...

risks:
- ...

next:
1. ...
```

- use the exact section names and order shown above
- include 1-5 assumptions
- include 1-5 options
- `decision` is required in every response
- `next` must be numbered and action-oriented

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

- max lines: 40
- max assumptions: 5
- max options: 5
- max risks: 5
