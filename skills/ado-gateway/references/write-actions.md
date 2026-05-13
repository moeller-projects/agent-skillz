# Write Actions

This skill supports a narrow mutation surface for Azure DevOps. It is not a general-purpose REST API writer.

## Safety Model

All write scripts are dry-run by default. A write is executed only when both flags are present:

```bash
--execute --confirm-write WRITE_TO_ADO
```

Dry-run output is a JSON action plan containing the HTTP method, URL, request body, required PAT scopes, and risk metadata.

## Create Work Item

Endpoint:

```http
POST /{organization}/{project}/_apis/wit/workitems/${type}?api-version=7.1
Content-Type: application/json-patch+json
```

Script:

```bash
./scripts/create-work-item.sh \
  --organization example-org \
  --project example-project \
  --type Bug \
  --title "Checkout fails" \
  --description "Observed during checkout."
```

Optional fields can be supplied as JSON object:

```bash
--fields-json '{"Microsoft.VSTS.Common.Priority":1,"System.Tags":"checkout;bug"}'
```

## Create Pull Request

Endpoint:

```http
POST /{organization}/{project}/_apis/git/repositories/{repositoryId}/pullrequests?api-version=7.1
Content-Type: application/json
```

Script:

```bash
./scripts/create-pull-request.sh \
  --organization example-org \
  --project example-project \
  --repository-id example-repo \
  --source-branch feature/my-change \
  --target-branch main \
  --title "Add checkout validation" \
  --description "Adds validation and tests."
```

Branches are normalized to `refs/heads/<name>` when the prefix is omitted.

## Create Work Item Comment

Endpoint:

```http
POST /{organization}/{project}/_apis/wit/workItems/{workItemId}/comments?api-version=7.1-preview.4
Content-Type: application/json
```

Script:

```bash
./scripts/create-work-item-comment.sh \
  --organization example-org \
  --project example-project \
  --work-item-id 456 \
  --text "<p>Ready for validation.</p>"
```

Request body shape:

```json
{"text":"<p>Ready for validation.</p>"}
```

Required scopes:

- Work Items: Read & write
- OAuth: `vso.work_write`

## Optional Mention Helpers for Work Item Comments

Mention markup syntax:

```html
<a href="#" data-vss-mention="version:2.0,{userID}">@Name</a>
```

Generate markup from a known descriptor/user id:

```bash
./scripts/format-work-item-mention.sh \
  --mention-id aad.abcdef1234567890 \
  --display-name "Ada Lovelace"
```

Resolve a user by email through Azure DevOps Graph API and emit ready-to-insert mention markup:

```bash
./scripts/resolve-ado-user.sh \
  --organization example-org \
  --email ada@example.com
```

`resolve-ado-user.sh` uses Azure DevOps Graph API (`vssps.dev.azure.com`) with the same `AZURE_DEVOPS_PAT`. If no user is found (or multiple users match), it fails and does not emit degraded mention markup.

## Create PR Comment Thread

General thread:

```bash
./scripts/create-pr-comment.sh \
  --mode thread \
  --organization example-org \
  --project example-project \
  --repository-id example-repo \
  --pull-request-id 123 \
  --content "Please consider extracting this validation."
```

Inline thread:

```bash
./scripts/create-pr-comment.sh \
  --mode thread \
  --organization example-org \
  --project example-project \
  --repository-id example-repo \
  --pull-request-id 123 \
  --content "This branch needs a null guard." \
  --file-path src/order.ts \
  --side right \
  --line 42
```

Inline thread spanning a line range (optional `--end-line`):

```bash
./scripts/create-pr-comment.sh \
  --mode thread \
  --organization example-org \
  --project example-project \
  --repository-id example-repo \
  --pull-request-id 123 \
  --content "This entire block should be extracted into a helper." \
  --file-path src/order.ts \
  --side right \
  --line 42 \
  --end-line 55
```

When `--end-line` is omitted the thread anchors to the single line given by `--line`. When provided, `--end-line` must be an integer greater than or equal to `--line`; the ADO API sets `rightFileEnd.line` (or `leftFileEnd.line`) to that value, causing the comment to highlight the entire range in the diff view.

> **File path constraint:** `--file-path` must be a path relative to the repository root (e.g., `src/order.ts` or `/src/order.ts`). A leading `/` is accepted as a repo-root prefix and is equivalent to omitting it. Do not supply a filesystem absolute path (e.g., `/home/user/repo/src/order.ts`). The Azure DevOps API maps `filePath` directly to the in-repository path, so a filesystem absolute path will not resolve to any file in the diff and the thread will fail to anchor.

## Reply to Existing PR Thread

```bash
./scripts/create-pr-comment.sh \
  --mode reply \
  --organization example-org \
  --project example-project \
  --repository-id example-repo \
  --pull-request-id 123 \
  --thread-id 99 \
  --content "Fixed in the latest push."
```

## Explicitly Unsupported

- delete work items
- update work items
- approve/reject PRs
- complete/abandon/merge PRs
- add reviewers
- change branch policies
- arbitrary REST endpoint execution
