# Write Actions

This skill supports a narrow mutation surface for Azure DevOps. It is not a general-purpose REST API writer.

## Safety Model

All write scripts are dry-run by default. A write is executed only when both flags are present:

```bash
--execute --confirm-write I_UNDERSTAND_THIS_WRITES_TO_ADO
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
  --file-path /src/order.ts \
  --side right \
  --line 42
```

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
