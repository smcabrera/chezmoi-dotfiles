---
name: git-commit
description: Make git commits with automatic pre-commit failure handling
---

## Overview

This skill handles git commits with automatic pre-commit hook failure resolution. When asked to make a commit, it will:

1. Run `git commit` with `OVERCOMMIT_DISABLE=0` to enable pre-commit hooks
2. If pre-commit hooks fail, analyze the failures and attempt to fix them
3. Retry the commit after addressing any issues

## Instructions

When the user asks you to make a commit:

1. **Stage the changes** (if not already staged):
   ```bash
   git add -A
   ```

2. **Attempt the commit** with pre-commit hooks enabled:
   ```bash
   OVERCOMMIT_DISABLE=0 git commit -m "<commit message>"
   ```

3. **If the commit fails due to pre-commit hooks**:
   - Analyze the pre-commit output to identify specific failures
   - Common pre-commit failures include:
     - Linting errors (ESLint, RuboCop, etc.)
     - Formatting issues
     - Missing trailing newlines
     - Large files
     - Security issues
   
4. **Attempt to fix the failures**:
   - For linting errors: Fix the specific issues mentioned in the output
   - For formatting: Run the appropriate formatter
   - For other issues: Address them based on the pre-commit output
   
5. **Re-stage any fixed files**:
   ```bash
   git add <fixed files>
   ```

6. **Retry the commit**:
   ```bash
   OVERCOMMIT_DISABLE=0 git commit -m "<commit message>"
   ```

7. **If failures persist after 2-3 attempts**:
   - Report the specific issues to the user
   - Ask if they want to:
     - Skip the failing hooks with `OVERCOMMIT_DISABLE=1`
     - Manually fix the issues
     - Abort the commit

## Example Usage

User: "Please commit these changes with the message 'Add user authentication'"

You would:
1. Stage all changes
2. Run `OVERCOMMIT_DISABLE=0 git commit -m "Add user authentication"`
3. If pre-commit fails, analyze and fix the issues
4. Retry the commit
5. Report success or persistent failures to the user