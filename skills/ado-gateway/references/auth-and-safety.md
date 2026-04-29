# Auth and Safety

- Use `AZURE_DEVOPS_PAT` by default. Allow explicit PAT input only when the caller requests it.
- Never echo the PAT, place it in generated artifacts, or persist it in example files.
- Use GET requests only. Do not add POST, PATCH, PUT, or DELETE helpers.
- Do not include raw thread payloads unless the caller explicitly requests them.
- If dependencies are missing, return blocker output instead of attempting a degraded network call.
