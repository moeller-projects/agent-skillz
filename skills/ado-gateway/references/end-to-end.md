# End-to-End Bash Flow

```bash
export AZURE_DEVOPS_PAT=...

./scripts/generate-handoff.sh \
  --pull-request-url "https://dev.azure.com/example-org/example-project/_git/example-repo/pullrequest/123" \
  --work-item-id 456 \
  > /tmp/ado-handoff.json
```

The emitted JSON can be passed directly to `openspec-gateway/scripts/spec-from-handoff.sh`.
