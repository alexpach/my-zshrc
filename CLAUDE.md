# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

Personal Zsh dotfiles configuration. Files are symlinked into `$HOME` as hidden files via `install.sh`.

## Installation

Two configs are available depending on the machine:

- **Full setup** (`zshrc` + Prezto): run `./install.sh`, which symlinks all dotfiles and offers to clone Prezto automatically if missing.
- **Portable** (`zshrc-portable`): single self-contained file, no external dependencies. Copy it to `~/.zshrc` on any machine with just zsh installed.

## No Build/Test Commands

This is a pure shell configuration repository. Changes are validated by sourcing the files in a live shell session.

## File Load Order & Roles

Zsh sources these files in this sequence:

1. **`zshenv`** — Always sourced first (even in scripts). Only ensures non-login shells source `zprofile` for consistent PATH. Keep this minimal.
2. **`zprofile`** — Login shell setup: PATH construction, EDITOR/BROWSER/PAGER/LANG.
3. **`zshrc`** — Interactive shell config: loads Prezto, adds tool integrations (zoxide, fzf, NVM), extends PATH.
4. **`zlogin`** — Post-zshrc login hook: compiles Prezto's zcompdump in background, shows `fortune -s`.
5. **`zpreztorc`** — Prezto-specific settings. Read by Prezto before it loads its modules. Module list and prompt theme live here.
6. **`zlogout`** — Interactive logout: prints a farewell quote.

## Key Architecture Decisions

**Prezto** is the shell framework, loaded from `$HOME/src/prezto/init.zsh` (external dependency, not bundled). Active modules (in load order): `environment`, `terminal`, `editor`, `history`, `directory`, `spectrum`, `utility`, `completion`, `history-substring-search`, `prompt`, `git`, `homebrew`, `osx`, `ssh`, `archive`.

**PATH layering**: Built in `zprofile` (`~/bin`, `/opt/homebrew/bin`, `/usr/local/bin`), then extended in `zshrc` (`~/.local/bin`, `~/.lmstudio/bin`). Homebrew takes priority over system paths.

**Optional tools**: `zoxide`, `fzf`, and `nvm` are all guarded — missing tools are silently skipped.

**NVM lazy-loading**: Stub functions for `nvm`/`node`/`npm`/`npx` defer sourcing `nvm.sh` until first use, avoiding startup overhead.

**Terminal title**: Managed by Prezto's `terminal` module (`auto-title 'yes'` in `zpreztorc`), format `%n@%m: %s`.
