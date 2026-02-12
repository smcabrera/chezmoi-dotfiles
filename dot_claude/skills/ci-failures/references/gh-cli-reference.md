# GitHub CLI Reference for CI Failures

Quick reference for `gh` commands used in this skill.

## gh run list

List workflow runs.

```bash
# Failed runs (most common use)
gh run list -s failure

# With limit
gh run list -s failure --limit 5

# Specific branch
gh run list -s failure --branch main

# Specific workflow
gh run list -w "CI" -s failure

# JSON output for parsing
gh run list -s failure --json databaseId,displayTitle,headBranch,conclusion,createdAt,workflowName --limit 5
```

### Status Options (-s)

| Status | Meaning |
|--------|---------|
| `failure` | Run failed |
| `success` | Run passed |
| `cancelled` | Run was cancelled |
| `in_progress` | Currently running |
| `queued` | Waiting to run |

### JSON Fields

```bash
gh run list --json <fields>
```

Available fields:
- `databaseId` - Numeric ID for `gh run view`
- `displayTitle` - Commit message or PR title
- `headBranch` - Branch name
- `conclusion` - failure/success/cancelled
- `createdAt` - ISO timestamp
- `workflowName` - Name of workflow file
- `event` - push/pull_request/schedule
- `status` - completed/in_progress
- `url` - Web URL to run

---

## gh run view

View details of a specific run.

```bash
# View run in terminal
gh run view <RUN_ID>

# Failed job logs only (most useful!)
gh run view <RUN_ID> --log-failed

# All logs (can be huge)
gh run view <RUN_ID> --log

# JSON output
gh run view <RUN_ID> --json jobs,conclusion,headBranch,createdAt

# Open in browser
gh run view <RUN_ID> --web
```

### JSON Fields

```bash
gh run view <ID> --json <fields>
```

Available fields:
- `jobs` - Array of job objects
- `conclusion` - Overall result
- `headBranch` - Branch
- `createdAt` - Start time
- `updatedAt` - End time
- `workflowName` - Workflow name
- `url` - Web URL

### Job Object Fields

Within `jobs` array:
```json
{
  "name": "test",
  "conclusion": "failure",
  "steps": [
    {
      "name": "Run tests",
      "conclusion": "failure",
      "number": 5
    }
  ]
}
```

---

## Common jq Filters

```bash
# Get failed job names
gh run view <ID> --json jobs | jq '.jobs[] | select(.conclusion=="failure") | .name'

# Get run IDs of failures
gh run list -s failure --json databaseId | jq '.[].databaseId'

# Most recent failure ID
gh run list -s failure --json databaseId --limit 1 | jq '.[0].databaseId'

# Failed runs with branch info
gh run list -s failure --json databaseId,headBranch,displayTitle | jq '.[] | "\(.databaseId): \(.headBranch) - \(.displayTitle)"'
```

---

## gh run rerun

Re-run workflows.

```bash
# Re-run only failed jobs
gh run rerun <RUN_ID> --failed

# Re-run entire workflow
gh run rerun <RUN_ID>

# Debug mode (SSH access)
gh run rerun <RUN_ID> --debug
```

---

## gh run download

Download artifacts from a run.

```bash
# Download all artifacts
gh run download <RUN_ID>

# Specific artifact
gh run download <RUN_ID> -n artifact-name

# List artifacts
gh run view <RUN_ID> --json artifacts | jq '.artifacts[].name'
```

---

## Authentication

```bash
# Check auth status
gh auth status

# Login
gh auth login

# Check repo context
gh repo view --json name,owner -q '"\(.owner.login)/\(.name)"'
```

---

## Useful Combinations

### Quick Failure Summary

```bash
# One-liner: show recent failures with branches
gh run list -s failure --limit 5 --json databaseId,headBranch,displayTitle \
  | jq -r '.[] | "#\(.databaseId) [\(.headBranch)] \(.displayTitle)"'
```

### Fetch and Parse Latest Failure

```bash
# Get most recent failure ID, then logs
RUN_ID=$(gh run list -s failure --json databaseId --limit 1 | jq '.[0].databaseId')
gh run view $RUN_ID --log-failed
```

### Check if Branch Has Failures

```bash
gh run list --branch feature-x -s failure --limit 1 --json databaseId | jq 'length > 0'
```

### Matrix Build Analysis

```bash
# Show all jobs and their status
gh run view <ID> --json jobs | jq '.jobs[] | {name: .name, conclusion: .conclusion}'
```

---

## Rate Limits

GitHub API has rate limits. For heavy usage:
- Authenticated: 5000 requests/hour
- Use `--limit` to reduce requests
- Cache results when exploring
