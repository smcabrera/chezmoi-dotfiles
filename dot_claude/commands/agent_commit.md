# Agent Commit

Look at the current git changes and create an appropriate commit message.

Make the commit with overcommit enabled to trigger git hooks:
```bash
OVERCOMMIT_DISABLE=0 git commit -m "<your message>"
```

If the git hooks fail:
1. Analyze the errors in the output
2. Make any necessary changes to fix the issues
3. Re-stage the fixed files with `git add`
4. Retry the commit

If you fail to make the hooks pass after 2 attempts, report the specific issues to the user and stop.
