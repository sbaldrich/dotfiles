# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository managed with GNU Stow. Each top-level directory (bash, zsh, vim, git, etc.) is a "stow package" that gets symlinked to $HOME when installed.

## Common Commands

### Installing/Updating dotfiles
```bash
# Install all packages (creates symlinks to $HOME)
make restow

# Install a specific package
stow --verbose --target=$HOME --restow zsh
```

### Uninstalling
```bash
# Remove all symlinks
make delete

# Remove a specific package
stow --verbose --target=$HOME --delete zsh
```

## Architecture

### Stow Package Structure
Each directory represents a stow package with its internal structure mirroring where files should be symlinked in $HOME:
- `zsh/.zshrc` → `$HOME/.zshrc`
- `bash/.bash_profile` → `$HOME/.bash_profile`
- `vim/.vimrc` → `$HOME/.vimrc`
- `tmuxinator/.config/tmuxinator/` → `$HOME/.config/tmuxinator/`

### Shell Configuration Split
The zsh configuration is deliberately split into two files:
- `zsh/.zshrc` - Lightweight loader that sources oh-my-zsh config and sets up version managers (sdkman, pyenv, nvm) and tool integrations (gcloud, terraform, leetcode, jbang)
- `oh-my-zsh/.oh-my-zsh.sh` - Main oh-my-zsh configuration with theme and plugins (git, nvm, emoji, gcloud, autojump, kubectl, ssh-agent)

This split prevents oh-my-zsh from taking over the entire `.zshrc` file.

### Local Customization
- `local/.local_aliases.sh` - User-specific aliases and configurations that should not be version controlled
- Both bash and zsh configurations source this file if it exists

### Version Managers & Tools Configured
The dotfiles configure integration for:
- **Language version managers**: sdkman (Java), pyenv (Python), nvm (Node.js)
- **Cloud tools**: Google Cloud SDK with completions
- **Infrastructure**: Terraform with completions
- **Development**: JBang (Java scripting), cargo (Rust)
- **Package managers**: pnpm, pipx
- **Productivity**: leetcode CLI with tmuxinator integration, custom bookmarking system (via `~/.bookmarks` directory)

### Vim Setup
The `.vimrc` uses vim-plug for plugin management and requires it to be installed separately (see README.md). Key plugins: UltiSnips, NERDTree, vim-airline.

## When Making Changes

- When adding new dotfiles, create them in the appropriate package directory following the stow structure
- Test changes with `stow -n` (dry-run) before actual installation
- The makefile uses `*/` to install all directories, so any new top-level directory will be automatically included
