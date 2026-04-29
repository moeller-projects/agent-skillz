# Handoff Contract

`openspec-gateway` consumes the exact contract in `assets/schemas/ado-openspec-handoff.schema.json`.

## Consumer Requirements

1. Reject malformed JSON or contracts from another producer.
2. Require `work_item.title` and `work_item.description` for spec generation from Azure DevOps input.
3. Treat missing acceptance criteria as allowed input, but surface it in open questions.
4. Never call Azure DevOps directly from this skill.
5. Preserve `pr_comments` as review context rather than treating them as requirements.
