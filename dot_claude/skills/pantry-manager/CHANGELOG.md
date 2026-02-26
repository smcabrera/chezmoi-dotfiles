# Changelog

## 2026-02-13 - CLI Refactor

### Added
- New `bin/pantry-manager` executable for direct command-line usage
- Comprehensive `README.md` with usage examples and documentation
- Test script `test_cli.sh` for validating CLI functionality
- All commands now accessible via simple CLI interface:
  - `pantry-manager add <ingredient> <quantity> <unit>`
  - `pantry-manager list`
  - `pantry-manager remove <ingredient>`
  - `pantry-manager recipes`
  - `pantry-manager recipe <id>`
  - `pantry-manager import <url>`
  - `pantry-manager search <query>`
  - `pantry-manager plan <N>`
  - `pantry-manager favorite <recipe_id> [rating] [notes]`

### Changed
- Updated `SKILL.md` to document new CLI usage
- Executable works from any directory (uses absolute paths internally)

### Features
- Proper command routing with error handling
- User-friendly help messages
- Command-specific usage hints
- Works standalone or via Claude Code skill integration
- Can be added to PATH for system-wide access

### Technical Details
- Uses `File.expand_path(__FILE__)` to find lib directory
- Proper shebang `#!/usr/bin/env ruby` for portability
- Exit codes for proper shell integration
- Graceful error handling with helpful messages
