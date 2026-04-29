# Normalization Rules

## Work Item Fields

- `title` ← `fields.System.Title`
- `description` ← stripped HTML from `fields.System.Description`
- `acceptance_criteria` ← `fields.Microsoft.VSTS.Common.AcceptanceCriteria`, then `fields.Custom.AcceptanceCriteria`
- `repro_steps` ← bug-only `fields.Microsoft.VSTS.TCM.ReproSteps`, then `fields.Custom.ReproSteps`
- `system_info` ← bug-only `fields.Microsoft.VSTS.TCM.SystemInfo`, then `fields.Custom.SystemInfo`
- `tags` ← `fields.System.Tags`
- `state` ← `fields.System.State`

## PR Comment Fields

- Flatten thread comments into individual comment records.
- Preserve `thread_id`, `comment_id`, author, content, file path, side, line range, and timestamps.
- Mark deleted comments with `comment_is_deleted: true`; do not drop them silently.

## Text Handling

- Strip basic HTML tags and decode common entities.
- Preserve line breaks from paragraph and list tags where possible.
- Redact obvious bearer tokens and PAT-like values before emitting the contract.
