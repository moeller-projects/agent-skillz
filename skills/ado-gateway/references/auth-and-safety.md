# Auth and Safety

- Use `AZURE_DEVOPS_PAT` by default. Allow explicit PAT input only when the caller requests it.
- Never echo the PAT, place it in generated artifacts, or persist it in example files.
- Read flows use GET requests only.
- Write flows are limited to the dedicated scripts for creating work items, creating pull requests, and adding or replying to pull request comments.
- Every write script must default to dry-run and require both `--execute` and `--confirm-write I_UNDERSTAND_THIS_WRITES_TO_ADO` before network mutation.
- Use bash entrypoints only. If text normalization or JSON assembly is needed, rely on Python stdlib or jq helpers from bash rather than PowerShell or Perl.
- Do not include raw thread payloads unless the caller explicitly requests them.
- If dependencies are missing, return blocker output instead of attempting a degraded network call.
- Required PAT scopes should be least-privilege: Work Items read/write for work item creation, Code read/write for pull request and PR comment creation.
