---
name: project-todos
description: Use when user mentions wanting to implement a feature, suggests adding functionality, or casually notes a future enhancement - creates a new issue directory under ~/Dropbox/GoatBot/dev/projects/[project]/issues/[slug]-[YYYY-MM-DD]/ for tracking in the GoatBot dev workflow
---

# Project TODOs

Automatically capture feature requests and ideas as issue directories in the GoatBot dev workflow when users mention them.

## Overview

When users mention features they'd like to implement (even casually), create an issue directory under `~/Dropbox/GoatBot/dev/projects/[project]/issues/` so the idea is captured and ready for future `/workflows` steps (brainstorm, research, plan). Do not start implementing — just create the directory.

## When to Use

**Trigger phrases:**
- "I'd like to implement..."
- "We should add..."
- "Would be nice to have..."
- "TODO: need to..."
- "Future feature: ..."
- "Next, we need..."
- Any mention of desired functionality

**Don't use when:**
- User is asking about existing features
- Discussing current implementation details
- User explicitly says "don't track this"

## Workflow

1. **Detect**: User mentions a feature or functionality they want
2. **Extract**: Identify the feature description(s)
3. **Determine project**: Run `git remote get-url origin` and extract the repo name, or use `basename $(git rev-parse --show-toplevel)`. If not in a git repo, ask the user for the project name.
4. **Build slug**: Convert the feature description to kebab-case (lowercase, spaces to hyphens, strip punctuation)
5. **Create directory**: `~/Dropbox/GoatBot/dev/projects/[project]/issues/[slug]-[YYYY-MM-DD]/` — empty, no files inside
6. **Confirm**: Report the created issue path to the user

## Directory Structure

```
~/Dropbox/GoatBot/dev/
└── projects/
    └── [project]/               # kebab-case repo name
        └── issues/
            └── [slug]-[date]/   # e.g. add-barcode-scanning-2026-02-18
                ├── spec.md      # added later by /workflows:brainstorm
                ├── research.md  # added later by /workflows:research
                └── plan.md      # added later by /workflows:plan
```

The directory is created **empty**. Files inside are added by later workflow steps.

## Implementation Steps

### 1. Detect Feature Mention

Listen for phrases indicating desired functionality. Extract the core feature description(s).

### 2. Determine Project Name

```bash
# Try to get repo name from git remote
git remote get-url origin 2>/dev/null | sed 's/.*\///' | sed 's/\.git$//'

# Fallback: basename of git root
basename "$(git rev-parse --show-toplevel 2>/dev/null)"
```

If neither works (not in a git repo), ask the user: "What project should I file this under?"

### 3. Build Slug

- Lowercase the feature description
- Replace spaces and underscores with hyphens
- Strip non-alphanumeric characters (except hyphens)
- Collapse multiple hyphens
- Example: "Add Barcode Scanning!" → `add-barcode-scanning`

### 4. Create the Directory

```bash
ISSUE_DIR="$HOME/Dropbox/GoatBot/dev/projects/[project]/issues/[slug]-[YYYY-MM-DD]"
mkdir -p "$ISSUE_DIR"
```

### 5. Confirm to User

Single issue:
```
Created issue: pantry-manager/add-barcode-scanning-2026-02-18
```

Multiple issues:
```
Created 2 issues:
- pantry-manager/pagination-2026-02-18
- pantry-manager/sorting-by-date-2026-02-18
```

Duplicate (directory already exists):
```
Issue already exists: pantry-manager/add-barcode-scanning-2026-02-18
```

## Common Mistakes

### Don't Start Implementation
User says "we should add search" → create the issue directory and confirm. Do not build the feature.

### Don't Over-Ask
Don't ask for priority, category, or description details. Infer the slug, create the directory, confirm. User can rename or refine later.

### Don't Miss Casual Mentions
Catch "would be nice to have" and similar phrasing — not just explicit "TODO:" comments.

### Don't Be Verbose
Wrong: "I've successfully created the issue directory for your feature request in the GoatBot dev workflow..."
Right: "Created issue: pantry-manager/add-barcode-scanning-2026-02-18"

## Edge Cases

**Multiple features in one message:**
Create a separate directory for each. Report all in a single confirmation block.

**Vague features:**
Add as-is with a reasonable slug. Better captured than lost.

**Not in a git repo:**
Ask the user: "What project should I file this under?"

**Duplicate (directory already exists):**
Do not create again. Report: "Issue already exists: [project]/[slug]-[date]"

## Quick Reference

| Situation | Action |
|-----------|--------|
| Feature mentioned | Create issue dir → confirm |
| Multiple features | Create each separately |
| Vague description | Use reasonable slug, create it |
| Not in a git repo | Ask for project name |
| Already exists | Skip, note it exists |
| User says "don't track" | Skip, acknowledge |

## Example Interactions

**Example 1: Single feature**
```
User: "I'd like to add barcode scanning"
Assistant: Created issue: pantry-manager/add-barcode-scanning-2026-02-18
```

**Example 2: Casual mention**
```
User: "Looking at this code... we should probably add caching at some point"
Assistant: Created issue: pantry-manager/add-caching-2026-02-18
[continues conversation about current code]
```

**Example 3: Multiple features**
```
User: "We need pagination and sorting by date"
Assistant: Created 2 issues:
- pantry-manager/pagination-2026-02-18
- pantry-manager/sorting-by-date-2026-02-18
```

**Example 4: Not in a git repo**
```
User: "We should add dark mode"
Assistant: I'm not in a git repo — what project should I file this under?
User: "pantry-manager"
Assistant: Created issue: pantry-manager/add-dark-mode-2026-02-18
```
