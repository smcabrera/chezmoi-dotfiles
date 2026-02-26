#!/bin/bash
# PostToolUse hook: apply chezmoi when skill files are written in the source directory.
# This deploys new/edited skills from chezmoi source to ~/.claude/skills/.

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

if [[ "$file_path" == *"/share/chezmoi/dot_claude/skills/"* ]]; then
  chezmoi apply ~/.claude/skills/ 2>/dev/null
fi
