---
name: github-summary
description: Generate a 6-month GitHub activity summary for peer reviews. Triggers on "github summary for [username]" or "github activity for [username]". Uses the gh CLI to fetch PRs merged, code reviews given from the current repo, then produces a standalone markdown summary organized by work themes.
---

# GitHub Summary for Peer Reviews

Generate a comprehensive activity summary for a GitHub user in the current repository.

## Prerequisites

- `gh` CLI installed and authenticated
- Run from within a git repository

## Workflow

### 1. Parse Time Range from User Input

Check the user's request for a time range. Look for patterns like:
- "3 months", "6 months", "1 year"
- "last quarter", "last 90 days"
- "since January", "from 2025-06-01"
- Any other time period specification

**Default: 6 months** if no time range is specified.

Examples:
- "github summary for john" → 6 months (default)
- "github summary for john last 3 months" → 3 months
- "github summary for sarah over the past year" → 1 year
- "github activity for alex last quarter" → 3 months (quarter)

### 2. Validate Environment

```bash
# Verify gh CLI is available and authenticated
gh auth status

# Get repo info
gh repo view --json nameWithOwner -q .nameWithOwner
```

### 3. Fetch Activity (Specified Time Range)

Calculate the start date based on the parsed time range:

```bash
# macOS (example for 6 months, adjust based on parsed time range)
START_DATE=$(date -v-6m +%Y-%m-%d)

# Linux (example for 6 months, adjust based on parsed time range)
START_DATE=$(date -d '6 months ago' +%Y-%m-%d)

# Adjust the date calculation based on the user's requested time range:
# - "3 months": -v-3m or '3 months ago'
# - "1 year": -v-1y or '1 year ago'
# - "90 days": -v-90d or '90 days ago'
# - "last quarter": -v-3m or '3 months ago'
```

#### PRs Authored (Merged)

```bash
gh pr list --author USERNAME --state merged --search "merged:>=$START_DATE" --json number,title,body,mergedAt,additions,deletions,files --limit 200
```

#### Code Reviews Given

```bash
gh api "repos/{owner}/{repo}/pulls?state=all&per_page=100" --paginate | \
  jq '[.[] | select(.merged_at >= "'$START_DATE'")] |
      .[].number' | \
  xargs -I {} gh api "repos/{owner}/{repo}/pulls/{}/reviews" | \
  jq '[.[] | select(.user.login == "USERNAME")]'
```

Or use search for review comments:

```bash
gh api "search/issues?q=repo:{owner}/{repo}+reviewed-by:USERNAME+is:pr+merged:>=$START_DATE" --paginate
```

### 4. Analyze and Summarize

After fetching the data, analyze it to produce:

1. **Work Buckets**: Group PRs by theme/area (infer from titles, file paths, PR bodies)
2. **Key Contributions**: Highlight significant PRs by size, impact, or complexity
3. **Review Activity**: Summarize volume and pattern of code reviews given
5. **Patterns**: Identify collaboration patterns, areas of ownership, throughput

### 5. Output Format

Produce a markdown summary with this structure:

```markdown
# GitHub Activity Summary: [Username]
**Period**: [Start Date] – [Today]
**Repository**: [repo name]

## Work Themes

### [Theme 1: e.g., Billing System]
- Brief description of the body of work
- Key PRs: #123, #456, #789
- Impact/scope notes

### [Theme 2: e.g., CI/CD Improvements]
...

## Key Contributions

| PR | Title | Merged | Scope |
|----|-------|--------|-------|
| #123 | Title here | 2024-08-15 | +500/-200, 12 files |
...

## Code Reviews

- **Reviews given**: X PRs reviewed
- **Review style**: [observations about depth, areas reviewed]
- **Notable reviews**: PRs where they provided significant feedback

## Patterns & Observations

- Areas of ownership
- Collaboration patterns
- Throughput/velocity notes
- Notable contributions worth highlighting in a peer review
```

## Notes

- If `gh` commands fail due to rate limits, wait and retry or reduce `--limit`
- For large repos, the review data may require multiple API calls
- Focus on quality over completeness—highlight what matters for a peer review
