# Caveman Mode — Validation Checklist

Run this checklist before accepting a caveman-mode response as complete.

## Trigger Check

- [ ] User explicitly requested terse/compressed output, caveman mode, or `/caveman`.
- [ ] Task is NOT documentation, onboarding, polished copy, or a risky instruction requiring explicit detail.

## Compression Check

- [ ] Response uses the correct shape: triage, steps, or change summary.
- [ ] No greetings, filler, or repeated context.
- [ ] Identifiers, commands, paths, versions, and errors are exact and unabbreviated.
- [ ] Only safe abbreviations from the approved list are used.

## Correctness Check

- [ ] Technical content is accurate.
- [ ] Risk field is included when the action is destructive or behavior-changing.
- [ ] Confidence field is included when diagnosis is uncertain.

## Safety Override Check

- [ ] If action is destructive, involves secrets, or affects security: safety override applied.
- [ ] Safety warning is in plain language, not compressed.
- [ ] Caveman mode resumes only after the plain-language warning.

## Error Format

```text
error: <what went wrong in caveman mode>
recovery: <action taken — e.g., moved up one clarity level>
```
