---
name: linear-summary
description: Generate a 6-month Linear activity summary for peer reviews. Triggers on "linear summary for [username]" or "linear activity for [username]". Uses the Linear MCP to fetch projects and issues from the workspace, then produces a standalone markdown summary organized by work themes.
---

# Linear Summary for Peer Reviews

Generate a comprehensive activity summary for a Linear user in the current workspace.

## Prerequisites

- Linear MCP configured and authenticated
- User has access to the Linear workspace

## Workflow

### 1. Parse Time Range from User Input

Check the user's request for a time range. Look for patterns like:
- "3 months", "6 months", "1 year"
- "last quarter", "last 90 days"
- "since January", "from 2025-06-01"
- Any other time period specification

**Default: 6 months** if no time range is specified.

Examples:
- "linear summary for john" → 6 months (default)
- "linear summary for john last 3 months" → 3 months
- "linear summary for sarah over the past year" → 1 year
- "linear activity for alex last quarter" → 3 months (quarter)

### 2. Identify the User

Ask for the user's name, email, or Linear user ID. Then use the Linear MCP to resolve it:

```
mcp__plugin_linear_linear__list_users with query parameter
```

Or if they say "me":

```
mcp__plugin_linear_linear__get_user with query="me"
```

### 3. Calculate Time Range

Calculate the ISO-8601 date based on the parsed time range (default: 6 months):

```
# ISO-8601 duration format examples:
# 3 months: -P3M
# 6 months: -P6M (default)
# 1 year: -P1Y
# 90 days: -P90D
# 1 quarter: -P3M

# Or explicit ISO date:
# Example: 2025-07-27 if today is 2026-01-27 and range is 6 months
```

Use this as the `updatedAt` filter parameter (format: `-P6M` for duration or explicit ISO date).

### 4. Fetch Activity Data

#### Projects Involvement

Fetch projects where the user was a member:

```
mcp__plugin_linear_linear__list_projects
  member: [user identifier]
  updatedAt: [calculated duration, e.g., -P6M for 6 months]
  limit: 100
  includeArchived: false
```

For key projects, get full details including description and milestones:

```
mcp__plugin_linear_linear__get_project
  query: [project id or name]
```

#### Issues Completed/Worked On

Fetch issues assigned to the user:

```
mcp__plugin_linear_linear__list_issues
  assignee: [user identifier]
  updatedAt: [calculated duration, e.g., -P6M for 6 months]
  limit: 250
  includeArchived: true
  orderBy: updatedAt
```

Consider fetching across different states to see completed vs. in-progress work.

For significant issues, get full details including relations and attachments:

```
mcp__plugin_linear_linear__get_issue
  id: [issue id]
  includeRelations: true
```

### 5. Analyze and Summarize

After fetching the data, analyze it to produce:

1. **Work Themes**: Group projects and issues by theme/area (use project groupings, issue labels, or infer from titles)
2. **Project Leadership**: Identify projects they led, contributed to, or collaborated on
3. **Issue Patterns**: Summarize types of issues (features, bugs, tech debt), scope, complexity
4. **Collaboration**: Note cross-team work, blocking/blocked relationships, team dynamics
5. **Impact**: Look for quantifiable outcomes, completed milestones, shipped features

### 6. Output Format

Produce a markdown summary with this structure:

```markdown
# Linear Activity Summary: [Username]
**Period**: [Start Date] – [Today]
**Workspace**: [Linear workspace name]

## Projects

### [Project 1: e.g., Persistent Chat Infrastructure]
- **Role**: [Lead / Contributor / Collaborator]
- **Status**: [Active / Completed / Planned]
- **Scope**: Brief description of the project
- **Key contributions**: What they specifically worked on
- **Impact**: Outcomes, milestones reached, value delivered

### [Project 2: e.g., Natural Language Recruiting]
...

## Issue Summary by Theme

### [Theme 1: e.g., Chat Features]
- **Issues completed**: X issues
- **Notable work**:
  - [ISSUE-123] Title - brief impact note
  - [ISSUE-456] Title - brief impact note
- **Patterns**: Type of work (features, bugs, refactoring)

### [Theme 2: e.g., Developer Experience]
...

## Key Contributions

| Issue/Project | Title | Completed | Type | Impact |
|---------------|-------|-----------|------|--------|
| [ISSUE-123] | Title here | 2025-08-15 | Feature | Description |
| [PROJECT-1] | Project name | Ongoing | Initiative | Description |
...

## Collaboration Patterns

- **Cross-team work**: Teams/people they collaborated with
- **Blocking/Dependencies**: How they unblocked others or navigated blockers
- **Code reviews**: If visible in issue comments/activity
- **Mentorship**: Evidence of helping others

## Patterns & Observations

- Areas of ownership and expertise
- Velocity and throughput trends
- Types of contributions (strategic vs. tactical, new features vs. maintenance)
- Growth trajectory over the period
- Notable achievements worth highlighting in a peer review
```

## Notes

- If API rate limits are hit, reduce `limit` parameters or add delays
- Focus on completed and high-impact work—not every issue needs to be listed
- Look for stories in the data: what themes emerge? What did they ship?
- Use project and issue descriptions to understand context
- Cross-reference with GitHub activity if available for a complete picture
- Prioritize quality insights over comprehensive lists
