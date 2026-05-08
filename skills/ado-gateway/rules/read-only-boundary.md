# Read-Only Boundary

- Read-mode scripts may only use GET requests to Azure DevOps APIs.
- Keep read-mode output deterministic and safe for downstream normalization.
- Do not add mutation flags to read-mode scripts.
- Write-mode scripts must live in separate, clearly named files and follow `rules/write-boundary.md`.
