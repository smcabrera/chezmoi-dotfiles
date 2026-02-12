---
name: local-ci
description: Use when preparing to test a feature branch locally, when asked to identify tests that might catch regressions, or when tracking test results before pushing to CI. Triggers on "run tests for this branch", "what tests should I run", "run tests related to changes", "test my changes", "identify tests for this PR", "which tests to run", "find tests for my changes", "run relevant tests", "test coverage for changes", or similar requests about testing branch/PR changes
---

# Local CI

## Overview

Analyze diffs between feature and main branches to identify tests that might reveal regressions. Generate a simple test list that a runner script processes until all tests pass.

## When to Use

- Starting to test a feature branch locally
- Asked "what tests should I run?"
- Need to track test results across multiple runs

## Output Files

All files go in `tmp/`:

| File | Purpose |
|------|---------|
| `tmp/local-ci-tests.txt` | One test path per line. Runner removes passing tests. Empty = done. |
| `tmp/run-local-ci.rb` | Runner script. Copy from skill assets. |

## Workflow

1. **Generate test list** → `tmp/local-ci-tests.txt`
2. **Copy runner script** → `tmp/run-local-ci.rb`
3. **User runs** → `ruby tmp/run-local-ci.rb`
4. **Repeat step 3** until file is empty

## Test List Format

Plain text, one test per line:

```
spec/models/user_spec.rb
spec/controllers/users_controller_spec.rb
app/javascript/components/User.spec.tsx
```

No prioritization, no metadata. Just paths.

## Test Identification Heuristics

1. **Direct mapping:** `app/models/user.rb` → `spec/models/user_spec.rb`
2. **Grep for usage:** Find specs that reference changed classes/methods
3. **Related features:** Other code in same domain
4. **Config changes:** If config touched, test code that reads that config

## Runner Script

**Copy the runner script from the skill directory to `tmp/`:**

```bash
cp ~/.claude/skills/local-ci/run-local-ci.rb tmp/
```

The script:
- Detects and uses `parallel_rspec` when available
- Falls back to standard `bundle exec rspec` otherwise
- Outputs JSON results for parsing
- Removes passing tests from the list
- Keeps failed tests for the next run

## Adding CI Failures

If CI reveals failures not in your list, just append them:

```bash
echo "spec/path/missed_spec.rb" >> tmp/local-ci-tests.txt
```

Then run the script again.
