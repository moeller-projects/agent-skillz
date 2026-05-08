# Write Boundary

Allowed write scripts:

- `scripts/create-work-item.sh`
- `scripts/create-pull-request.sh`
- `scripts/create-pr-comment.sh`

Rules:

1. Default to dry-run.
2. Require `--execute`.
3. Require `--confirm-write I_UNDERSTAND_THIS_WRITES_TO_ADO`.
4. Emit a JSON action plan before execution when not executing.
5. Use fixed Azure DevOps endpoint templates only.
6. Do not accept arbitrary URL or arbitrary method input.
7. Do not support DELETE.
8. Do not support PR merge/complete/abandon/approve/reject.
9. Do not echo PATs.
10. Use least-privilege PAT scopes.
