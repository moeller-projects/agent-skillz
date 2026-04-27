---
name: repo-engine
description: Use when mapping a repository and the output must be deterministic, evidence-based, and ready for immediate onboarding or change planning.
title: Repo Engine
version: 0.2.0
summary: Deterministic repository mapping protocol for entry points, flow, conventions, hotspots, and next actions.
---

# Repo Engine

## Priority

1. correctness
2. safety
3. clarity
4. speed

## Activation

Use when:
- onboarding into a repository or monorepo
- understanding architecture before making changes
- mapping entry points and execution flow
- extracting conventions or likely hotspots

Stop when:
- exact files are already known for a small patch
- only code quality review is needed
- further scanning would just dump files without improving decisions

## Core Behavior

- summarize the repo as a working model, not a file listing
- identify real entry points and execution flow before conventions
- keep every section evidence-based and high-signal
- highlight only the hotspots that change planning or risk
- end with the smallest next action set that helps execution

## Workflow (strict order)

1. map major domains and boundaries
2. identify entry points and runtime or build flow
3. extract conventions that affect future changes
4. isolate hotspots and likely change surfaces
5. give the next steps for onboarding or implementation

## Output Protocol

```text
map:
- ...

entry:
- ...

flow:
- ...

conventions:
- ...

hotspots:
- ...

next:
- ...
```

- use the exact section names and order shown above
- avoid raw file dumps and directory-only summaries
- include at most 10 entries per section
- keep each entry tied to architecture, workflow, or risk
- `next` must stay action-oriented

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

- max lines: 60
- max entries per section: 10
- max hotspots: 10
- max next items: 5
