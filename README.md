# my-zshrc

Personal Zsh configuration: a single self-contained `zshrc` with no external
dependencies. Works anywhere zsh is installed.

## Install

```bash
git clone git@github.com:alexpach/my-zshrc.git ~/src/my-zshrc
cd ~/src/my-zshrc
./install.sh
```

`install.sh` will:
- Symlink `zshrc` → `~/.zshrc` and `my-aliases` → `~/.my-aliases`
  (existing files are backed up with a timestamp)
- Clean up symlinks left over from the old Prezto-based setup
- Run `chezmoi apply` for private config if chezmoi is installed

Or just copy the one file to any machine:

```bash
cp zshrc ~/.zshrc
```

## What's inside

- PATH setup (`~/bin`, `~/.local/bin`, Homebrew, etc. — missing dirs skipped)
- Sensible history, directory, and completion options
- Fast startup: full `compinit` security audit at most once a day
  (`-C` otherwise), completion dump compiled in the background,
  NVM lazy-loaded on first use of `nvm`/`node`/`npm`/`npx`
- Prompt with user@host, path, git branch (via `vcs_info`), and exit code
- Emacs key bindings with up/down prefix history search
- Terminal title updates (current dir / running command)
- OS-aware `ls` colors (BSD `CLICOLOR` on macOS, `--color=auto` elsewhere)
- Optional tools guarded — [zoxide](https://github.com/ajeetdsouza/zoxide),
  [fzf](https://github.com/junegunn/fzf), [nvm](https://github.com/nvm-sh/nvm),
  and `fortune` are used if present, silently skipped if not

## Aliases

`my-aliases` (sourced from `~/.my-aliases` if present) holds aliases for git,
docker, networking, etc. It builds on the base `ls` alias defined in `zshrc`.

## Private config

Sensitive or machine-specific config (API keys, work aliases, etc.) goes in
`~/.my-private`, which is sourced by `zshrc` if it exists. This file is
**not** in this repo — manage it with [chezmoi](https://www.chezmoi.io):

```bash
brew install chezmoi
chezmoi init
chezmoi add ~/.my-private   # add the file to chezmoi management
chezmoi apply               # apply on subsequent machines
```
