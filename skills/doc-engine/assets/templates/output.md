# Doc Engine — Output Template

## Default (doc plan + changes + gaps)

```text
doc:
- purpose: <one sentence — what this document enables the reader to do>
- audience: <role and knowledge level, e.g., "backend engineer, unfamiliar with auth flow">
- structure:
  1. <section name> [<mode>] — <what it covers>
  2. <section name> [<mode>] — <what it covers>
  # <mode> must be one of: tutorial, how-to, reference, explanation — see rules/diataxis-mode.md

changes:
- <file or section> — <what changed and why>

gaps:
- <missing information or follow-up doc needed>
```

## Diff-Oriented Update (still include the full contract)

```text
doc:
- purpose: <what the updated document must enable>
- audience: <who reads the document and what they already know>
- structure:
  1. <section name> [<mode>] — <what stays or changes>

changes:
- <file> — update existing content via diff instead of full replacement

gaps:
- <missing information that still blocks publishing>

--- <file>
+++ <file>

@@ -<line>,<count> +<line>,<count> @@ <section heading>
- <removed line>
+ <added line>

reason: <why this change was made>
```

## Rules

- State purpose and audience before expanding any prose.
- Use diff format for changes to existing documents.
- List every gap explicitly; do not silently omit missing information.
- Every command, path, and step in the output must be verified as accurate.
