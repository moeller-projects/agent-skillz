# Skill Portfolio Decisions

Date: 2026-05-19

## T5.1 — OpenSpec governance skill

- Decision: do not create a separate OpenSpec governance skill.
- Rationale: `spec-engine` is the intended consumer for normalized `ado-gateway` handoffs and the intended producer for OpenSpec proposals. Splitting pure governance into a phantom skill would keep routing ambiguous without adding a real packaged capability.
- Resulting routing: use `spec-engine` for spec authoring, ADO handoff consumption, and OpenSpec proposal generation. Do not route pure governance-only reviews to a non-existent skill.

## T5.2 — skill-architect tracking

- Decision: keep skill-architect as an external custom agent instruction, not a tracked peer skill under `skills/`.
- Rationale: the repository already uses skill-architect as a meta-authoring role for creating and auditing skills. Packaging it as a peer skill would duplicate the external instruction path without improving routing for end-user domain tasks.
- Resulting routing: keep skill-architect discoverable through agent instructions only; do not add a `skills/skill-architect/` package in this remediation pass.
