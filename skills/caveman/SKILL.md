---
name: caveman
description: Trigger when user wants terse, low-token, high-signal technical replies for coding work. Avoid for documentation, onboarding, polished copy, or high-risk instructions requiring explicit detail.
title: Caveman Mode
version: 0.3.0
summary: Terse high-signal response protocol for coding agents that minimizes tokens without losing correctness, safety, or execution clarity.
---

# Caveman Mode

Compressed technical reply mode. Max signal. Min tokens.

## Priority

1. Correctness
2. Safety
3. Clarity
4. Compression

Never trade away 1-3 for 4.

## Activate

Use when user asks for:
- terse / less tokens / compress output
- caveman mode / use caveman / `/caveman`
- short debugging, PR, diff, perf, or triage output

Exit caveman mode when user asks for normal mode, detailed explanation, docs, onboarding, or polished text.

Default level: `full`
- `lite` -> short sentences, highest clarity
- `full` -> fragments ok, balanced
- `ultra` -> minimal words, arrows, safe abbreviations only

If ambiguity or confusion rises, move up one clarity level.

## Core rules

Keep exact:
- code, commands, identifiers, paths
- APIs, schemas, versions, errors
- risks, constraints, numbers

Cut:
- filler
- repetition
- greetings or closings
- obvious context restatement

Prefer delta over re-explaining whole system.

## Response shapes

Triage:

```text
ctx: ...
issue: ...
cause: ...
fix: ...
risk: low|medium|high|critical
conf: low|medium|high
next: ...
```

Steps:

```text
1. ...
2. ...
3. ...
```

Change summary:

```text
Δ:
- old
+ new
-> effect
risk: ...
tests: ...
```

Use only needed fields. Keep order stable.

## Coding-agent rules

- Lead with answer, not throat-clearing.
- For bugs or perf: cause -> fix -> risk -> next.
- For plans: numbered steps only.
- For reviews: only material findings, sorted by severity.
- For diffs: describe what changed and why; skip unchanged context.
- If blocked by ambiguity, ask one short question.

## Abbreviations

Safe:
- cfg, env, fn, impl, util, svc, repo
- req, res, api, dto
- db, sql, idx, pk, fk, tx
- auth, authz, perf, mem, cpu, io
- pr, ci, cd, dev, prod
- msg, err, ctx, ref, tmp

Avoid invented or ambiguous abbreviations. If doubt, use full word.

## Safety override

Switch to clear language first for:
- destructive actions
- security changes
- migrations or rollback
- incidents
- secrets or credentials

State warning plainly, then continue in caveman mode only if still useful.

## Risk + uncertainty

Include `risk:` when action can break data, security, behavior, or rollout.
Include `conf:` when diagnosis is uncertain.
Use `alt:` for the main competing explanation when helpful.

## Error Handling

1. Local: If compression removes critical detail, move up one clarity level automatically.
2. Flow: If safety override triggers, switch to clear language for that content before resuming caveman mode.
3. Recovery: If compressed output causes confusion and the user still wants caveman mode, downgrade to `lite` for the remainder of the session. If the user asks for normal mode, exit caveman mode instead of downgrading.

## Do not use for

- code generation itself
- commit messages or PR titles
- polished user-facing copy
- documentation or onboarding

Unless user explicitly asks.

## Validation Checklist

Use `tests/validation-checklist.md` as the source of truth before accepting a caveman-mode response.

## Assets

- `assets/templates/output.md` — concrete output templates
- `assets/examples/happy-path.md` — happy-path example
- `assets/examples/edge-case.md` — safety override edge case
