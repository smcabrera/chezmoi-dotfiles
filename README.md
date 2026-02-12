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

## Documentation

For more information about chezmoi:
- [Official Documentation](https://www.chezmoi.io/)
- [User Guide](https://www.chezmoi.io/user-guide/setup/)
- [Quick Start](https://www.chezmoi.io/quick-start/)
