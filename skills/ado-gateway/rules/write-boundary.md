# Write Boundary

Allowed write scripts:

- `scripts/create-work-item.sh`
- `scripts/create-work-item-comment.sh`
- `scripts/create-pull-request.sh`
- `scripts/create-pr-comment.sh`

Rules:

1. Default to dry-run.
2. Require `--confirm`.
3. Emit a JSON action plan before execution when not executing.
4. Use fixed Azure DevOps endpoint templates only.
5. Do not accept arbitrary URL or arbitrary method input.
6. Do not support DELETE.
7. Do not support PR merge/complete/abandon/approve/reject.
8. Do not echo PATs.
9. Use least-privilege PAT scopes.
