# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

Personal Zsh dotfiles. A single self-contained `zshrc` (no framework, no external dependencies) plus an alias file. Files are symlinked into `$HOME` as hidden files via `install.sh`, or `zshrc` can simply be copied to `~/.zshrc` on any machine.

## No Build/Test Commands

Pure shell configuration. Validate changes with `zsh -n zshrc` (syntax) and by sourcing in a live shell.

## Architecture

Everything lives in `zshrc`, in this order:

1. **PATH** — zsh `path` array with `(N)` qualifiers so missing dirs are dropped; `typeset -gU` deduplicates.
2. **Environment** — EDITOR/VISUAL/PAGER/LANG/LESS/BROWSER, only set if empty.
3. **History / directory / completion options** — `compinit` runs its full security audit at most once per day (dump younger than 24h → `compinit -C`); the dump is `zcompile`d in the background.
4. **Prompt** — static `PROMPT` using native `%(?..)` conditionals for the exit code; git branch via `vcs_info` precmd hook (the only reason `PROMPT_SUBST` is set).
5. **Terminal title** — precmd/preexec hooks; preexec sanitizes the command with `${(V)1}`.
6. **Tool integrations** — all guarded, silently skipped if absent: zoxide, fzf, `~/.my-aliases`, `~/.my-private`.
7. **NVM lazy-loading** — stub functions for `nvm`/`node`/`npm`/`npx` defer sourcing `nvm.sh` until first use.
8. **Greeting/farewell** — `fortune -s` on login; `zshexit` hook prints a quote on logout. Both guarded by `[[ -o LOGIN && -o INTERACTIVE && -t 2 ]]`.

Note: `add-zsh-hook` is explicitly autoloaded near the top — hooks throughout the file depend on it.

## Conventions

- The base `ls` alias (colors, `-Fv`) is OS-aware and lives in `zshrc`; `my-aliases` defines derived aliases (`l`, `ll`, `la`, …) on top of it.
- Don't alias over common binaries (e.g. `gh` is the GitHub CLI; history-grep is `hgrep`).
- Private/machine-specific config goes in `~/.my-private` (managed by chezmoi, never committed here).
