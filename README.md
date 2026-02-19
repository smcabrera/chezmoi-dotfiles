# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## Quick Setup on a New Machine

### One-Line Install

The fastest way to set up your dotfiles on a new machine:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply smcabrera
```

This command will:
1. Install chezmoi
2. Clone this dotfiles repository
3. Apply all dotfiles to your home directory

### Alternative: Manual Setup

If you prefer to review changes before applying:

```bash
# Install chezmoi (if not already installed)
sh -c "$(curl -fsLS get.chezmoi.io)"

# Initialize with your dotfiles repo
chezmoi init smcabrera

# Preview what changes would be made
chezmoi diff

# Apply the dotfiles
chezmoi apply
```

### Using Full Repository URL

You can also use the full repository URL:

```bash
chezmoi init --apply https://github.com/smcabrera/chezmoi-dotfiles.git
```

## Prerequisites

- Git (for cloning the repository)
- curl (for the installation script)

## Daily Operations

### Update dotfiles from repository

```bash
chezmoi update
```

This pulls the latest changes from the repository and applies them.

### Edit a dotfile

```bash
chezmoi edit ~/.bashrc
```

This opens the source file in your editor.

### Add a new dotfile

```bash
chezmoi add ~/.newconfig
```

### See what would change

```bash
chezmoi diff
```

### Apply pending changes

```bash
chezmoi apply
```

### Commit and push changes

```bash
chezmoi cd
git add .
git commit -m "Update dotfiles"
git push
exit
```

## What's Included

This repository manages configuration files for:
- Shell configurations (bash, zsh)
- Git configuration
- Vim/Neovim
- AeroSpace window manager
- ASDF version manager
- And more...

## GoatBot Dev Workflows

A set of Claude Code slash commands for managing software projects from idea to implementation. Commands live in `~/.claude/commands/workflows/`.

### Directory Structure

Projects and issues are stored in `~/Dropbox/GoatBot/dev/projects/`, mirroring GitHub's project → issue hierarchy (project = repo, issue = feature/ticket):

```
~/Dropbox/GoatBot/dev/
└── projects/
    └── [project]/               # kebab-case repo/codebase name
        └── issues/
            └── [slug]-[date]/   # e.g. cli-v1-2026-02-11
                ├── spec.md      # product requirements (from brainstorm)
                ├── research.md  # codebase findings (from research)
                └── plan.md      # implementation plan (from plan)
```

### The Workflow

Commands are designed to be run in sequence, each feeding the next:

```
brainstorm → research → plan → implement
                                   ↑
                               iterate (refine plan at any point)
```

### Commands

**`/workflows:brainstorm [project]/[issue]`**
Interactive thought partner that turns vague ideas into a clear `spec.md`. Asks one question at a time to clarify problem, goals, requirements, and out-of-scope items. When creating a new issue, asks for the project name and infers an issue slug from the topic, creating `issues/[slug]-[YYYY-MM-DD]/`. Saves to `spec.md`.

**`/workflows:research [project]/[issue]`**
Spawns parallel sub-agents to comprehensively document the codebase as it relates to the spec. Classifies research depth (High/Standard/Low) and automatically fetches external sources for high-risk topics (auth, payments, crypto). Pure documentation — no recommendations or critique. Saves to `research.md`.

**`/workflows:plan [project]/[issue]`**
Creates a phased implementation plan by reading the spec and research, then running additional codebase investigation. Interactive: asks clarifying questions, proposes design options, recommends a plan tier (Focused/Standard/Comprehensive), and gets sign-off on the phase structure before writing. All phases include separate Automated and Manual verification criteria. Saves to `plan.md`.

**`/workflows:iterate [project]/[issue] [feedback]`**
Updates an existing `plan.md` based on feedback. Surgical edits only — preserves good content and only researches what's needed for the specific change. Use this to add phases, adjust scope, or refine success criteria after the initial plan is written.

**`/workflows:implement [project]/[issue]`**
Executes the plan phase by phase. Reads `plan.md` and `research.md`, creates a task list, checks off items as they complete, and pauses after each phase for manual verification before proceeding. Updates checkboxes in `plan.md` to track progress.

### Argument Format

All commands take `[project]/[issue]` (e.g. `pantry-manager/cli-v1-2026-02-11`). Without an argument, commands auto-detect recently modified issues and present them as options. Issue slugs follow the format `[descriptive-kebab-case]-[YYYY-MM-DD]`.

### Typical Session

```bash
# Start a new feature idea
/workflows:brainstorm pantry-manager

# Research the codebase once you have a spec
/workflows:research pantry-manager/add-barcode-scanning-2026-02-18

# Create the implementation plan
/workflows:plan pantry-manager/add-barcode-scanning-2026-02-18

# Refine if needed
/workflows:iterate pantry-manager/add-barcode-scanning-2026-02-18 "add a rollback phase"

# Execute
/workflows:implement pantry-manager/add-barcode-scanning-2026-02-18
```

## Documentation

For more information about chezmoi:
- [Official Documentation](https://www.chezmoi.io/)
- [User Guide](https://www.chezmoi.io/user-guide/setup/)
- [Quick Start](https://www.chezmoi.io/quick-start/)
