# Skill version intent files

For any pull request that changes files under `skills/<skill-name>/`, add a matching intent file at:

- `.changes/skills/<skill-name>.json`

Intent file schema:

```json
{
  "bump": "patch",
  "summary": "Short changelog note (optional)"
}
```

- `bump` is required and must be one of: `major`, `minor`, `patch`
- `summary` is optional and is used in `skills/<skill-name>/CHANGELOG.md` during release bump automation

On merge to `main`, the Skill Release workflow:

1. detects changed skills,
2. reads each required intent file,
3. bumps version in `metadata.json`, `SKILL.md`, and `README.md`,
4. prepends changelog entries,
5. regenerates `skills/INDEX.md`,
6. commits release changes,
7. tags each released skill as `skill/<skill-name>/v<version>`,
8. uploads packed skill zip artifacts.
