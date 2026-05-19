# Caveman Mode

Version: 0.3.1

Token-efficient response protocol for coding agents.

## Best for

- debugging and incident triage
- PR review and diff summaries
- architecture tradeoffs
- performance analysis
- agent handoff/status updates

## Avoid for

- tutorials and onboarding
- polished user-facing writing
- documentation
- risky instructions without an explicit warning

## Levels

- `lite` -> concise, most readable
- `full` -> default, balanced compression
- `ultra` -> maximum compression without abbreviation soup

## Default shapes

- triage: `ctx / issue / cause / fix / risk / conf / next`
- steps: numbered list only
- change summary: `Δ / risk / tests`

## Guardrails

- Keep code, commands, paths, versions, and errors exact.
- Prefer deltas over full restatements.
- Include risk for destructive or behavior-changing advice.
- Include confidence when diagnosis is uncertain.
- Fall back to clearer language for security, migrations, rollback, incidents, or secrets.
