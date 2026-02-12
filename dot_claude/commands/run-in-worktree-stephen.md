---
description: Create a new worktree and implement requested changes in that worktree
---

Create a new git worktree for the following task and implement the requested changes:

```
$ARGUMENTS
```

Steps to complete:

1. **Prompt for a branch name if not provided**: The user should provide a branch name of the form user-name/team-123-description-of-branch. For example
stephen/rec-1504-add-llmchatactionsexecutionscontrollercreate-endpoint. If a branch name is not provided, prompt the user to enter one.

2. **See if a worktree already exists**: See if the worktree exists using `tree-me list`.

3. **Create and setup the worktree**: Run `bin/setup-worktree [branch-name]` to create a new worktree with all dependencies installed. If the worktree already exists, pass the `--no-create` flag to setup without creating a new worktree: `bin/setup-worktree [branch-name] --no-create`

4. **Navigate to the worktree**: Change to the worktree directory shown in the script output (typically `../trees/[branch-name]`)

5. **Implement the changes**: Make all the necessary code changes to complete the task in that worktree

6. **Verify the changes**: Run any relevant tests or checks to ensure the implementation works correctly

Task to complete: $ARGUMENTS
