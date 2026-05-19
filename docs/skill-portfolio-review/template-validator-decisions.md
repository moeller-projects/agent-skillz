# Template / Validator Decisions

Date: 2026-05-19
Task: T1.1

## Scope

- Audited every skill that has both `assets/templates/output.md` and `scripts/validate-output.sh`
- `delivery-engine` is already aligned and needs no follow-up change

## Decision Table

| Skill | Failure mode | Proposed resolution |
|---|---|---|
| `code-quality-engine` | The fast-path template uses `finding:` + `fix:` + `risk:` and omits the validator-required `findings:` and `patch-plan:` sections. | fix template |
| `doc-engine` | The diff-only template shape can be emitted without the validator-required `doc:`, `changes:`, and `gaps:` sections. The validator only supports diffs as an additional format detail, not as a standalone contract. | fix template |
| `ops-engine` | The minimal template omits validator-required sections: `plan:`, `checks:`, `rollback:`, and `security:`. | fix template |
| `repo-engine` | The template examples use `:` placeholders where the validator expects entries with an explanatory `—` segment for `repo_map` and `hotspots`. | fix template |
| `spec-engine` | The `spec-diff` template is not part of the validator contract, which only accepts freeform spec output or `output_format: openspec`. | fix template |
| `test-engine` | The fast-path template emits a single case block and omits validator-required `test-plan:`, `coverage-gaps:`, `cases:`, and `risk:` sections. | fix template |
| `thinking-engine` | The minimal template omits validator-required `assumptions:`, `options:`, and `recommendation:` sections and cannot satisfy the numbered-options check. | fix template |

## Notes

- Default rule applied: prefer fixing the template unless the validator clearly contradicts the intended contract.
- No validator change is required to resolve the current seven drift cases.
- `delivery-engine` remains the control case: its template already matches the validator contract closely enough for the planned portfolio-wide drift check.
