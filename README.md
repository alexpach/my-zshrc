# my-zshrc

Personal Zsh configuration. Two options depending on the machine:

- **Full setup** — Prezto-based, all features
- **Portable** — single file, no dependencies, works anywhere

## Full setup

### Prerequisites

- [Prezto](https://github.com/sorin-ionescu/prezto) at `~/src/prezto`
- Optional: [zoxide](https://github.com/ajeetdsouza/zoxide), [fzf](https://github.com/junzhuang/fzf), [nvm](https://github.com/nvm-sh/nvm)

### Install

```bash
git clone git@github.com:alexpach/my-zshrc.git ~/src/my-zshrc
cd ~/src/my-zshrc
./install.sh
```

`install.sh` will:
- Offer to clone Prezto automatically if not found
- Symlink all dotfiles to `$HOME`
- Run `chezmoi apply` for private config if chezmoi is installed

### Files

| File | Symlinked to | Purpose |
|------|-------------|---------|
| `zshrc` | `~/.zshrc` | Interactive shell, loads Prezto and tools |
| `zprofile` | `~/.zprofile` | Login shell: PATH, editors, language |
| `zpreztorc` | `~/.zpreztorc` | Prezto modules and theme (paradox) |
| `zshenv` | `~/.zshenv` | Minimal env, ensures PATH in non-login shells |
| `zlogin` | `~/.zlogin` | Post-login: compiles completions, shows fortune |
| `zlogout` | `~/.zlogout` | Farewell message on exit |
| `my-aliases` | `~/.my-aliases` | Aliases for git, docker, network, etc. |

## Portable setup

Single self-contained file, no external dependencies required.

```bash
cp zshrc-portable ~/.zshrc
# or
source /path/to/zshrc-portable
```

Includes: history settings, completion, emacs key bindings, up/down history search, colored prompt with exit code, terminal title, and the same optional tool guards (zoxide, fzf, nvm).

## Private config

Sensitive or machine-specific config (API keys, work aliases, etc.) goes in `~/.my-private`, which is sourced by both `zshrc` and `zshrc-portable` if it exists. This file is **not** in this repo — manage it with [chezmoi](https://www.chezmoi.io):

```bash
brew install chezmoi
chezmoi init
chezmoi add ~/.my-private   # add the file to chezmoi management
chezmoi apply               # apply on subsequent machines
```
