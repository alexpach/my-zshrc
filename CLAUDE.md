# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

Personal Zsh dotfiles. A single self-contained `zshrc` (no framework, no external dependencies) plus an alias file. Files are symlinked into `$HOME` as hidden files via `install.sh`, or `zshrc` can simply be copied to `~/.zshrc` on any machine.

## No Build/Test Commands

Pure shell configuration. Validate changes with `zsh -n zshrc` (syntax) and by sourcing in a live shell.

## Architecture

Everything lives in `zshrc`, in this order:

1. **PATH** — zsh `path` array with `(N)` qualifiers so missing dirs are dropped; `typeset -gU` deduplicates.
2. **Environment** — EDITOR/VISUAL/PAGER/LANG/LESS/BROWSER, only set if empty. Keg-only flex/bison `LDFLAGS`/`CPPFLAGS` are exported only if those Homebrew dirs exist (both `-L` paths in one `LDFLAGS` — a second `export LDFLAGS=` would clobber the first). `VIRTUAL_ENV_DISABLE_PROMPT=1` so the prompt owns the venv segment.
3. **History / directory / completion options** — `compinit` runs its full security audit at most once per day (dump younger than 24h → `compinit -C`); the dump is `zcompile`d in the background. `CORRECT` is unset (no autocorrection).
4. **Prompt** — `zshlex`, a segmented powerline prompt ported from the old Prezto theme to native `vcs_info` (no framework). Built at render time by `_zshlex_left`/`_zshlex_right` via `$(...)` under `PROMPT_SUBST`: left pill = host icon › pwd › git branch+status glyphs › venv; right pill = exit `✓/✘` › `user@host` › clock, right-aligned and hidden when the line is too narrow (`_zshlex_visible_width` measures on-screen width). Git status (staged/unstaged/untracked/action) comes from `vcs_info` styles plus a `+vi-untracked` hook. **Requires a Nerd Font** for the glyphs (stored as `$'\uXXXX'` escapes so the file stays ASCII). Per-host icons keyed on `${HOST%%.*}`. `TRAPWINCH` forces a redraw on resize.
5. **Terminal title** — precmd/preexec hooks; preexec sanitizes the command with `${(V)1}`.
6. **Tool integrations** — all guarded, silently skipped if absent: zoxide, fzf, `~/.my-aliases`, `~/.my-private`, iTerm2 shell integration; a stray `trash` function is `unfunction`'d so the `trash` binary on PATH wins.
7. **NVM lazy-loading** — stub functions for `nvm`/`node`/`npm`/`npx` defer sourcing `nvm.sh` until first use.
8. **Greeting/farewell** — `fortune -s` on login; `zshexit` hook prints a quote on logout. Both guarded by `[[ -o LOGIN && -o INTERACTIVE && -t 2 ]]`.

Note: `add-zsh-hook` is explicitly autoloaded near the top — hooks throughout the file depend on it.

## Conventions

- The base `ls` alias (colors, `-Fv`) is OS-aware and lives in `zshrc`; `my-aliases` defines derived aliases (`l`, `ll`, `la`, …) on top of it.
- Don't alias over common binaries (e.g. `gh` is the GitHub CLI; history-grep is `hgrep`).
- Private/machine-specific config goes in `~/.my-private` (managed by chezmoi, never committed here).
