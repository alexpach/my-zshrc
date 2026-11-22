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

For a remote host over ssh (backs up an existing `~/.zshrc` to `~/.zshrc.bak.<timestamp>`):

```bash
./install-remote.sh [--with-aliases] [user@]host
```

## What's inside

- PATH setup (`~/bin`, `~/.local/bin`, Homebrew, etc. — missing dirs skipped)
- Per-window history: every shell appends to `~/.zsh_history` immediately,
  but arrow-up only walks the current window's commands (no live cross-feed
  between windows; `fc -RI` pulls in other windows' entries on demand)
- Locale guard: if the effective locale isn't UTF-8 (unset, or never
  generated on the host), forces `C.UTF-8` for the session and prints how to
  fix the host permanently (the prompt glyphs need UTF-8)
- Fast startup: full `compinit` security audit at most once a day
  (`-C` otherwise), completion dump compiled in the background,
  Homebrew/Docker/generated completions (tailscale, npm, aws) picked up when present,
  NVM lazy-loaded on first `nvm`; `node`/`npm`/`npx` run straight from the newest installed version on PATH
- Powerline-style prompt pill (**Nerd Font required**): host icon,
  user@host, path, git branch and status (via `vcs_info`), venv
- Transient prompt: accepted lines repaint as plain
  `user@host:~/dir ❯ cmd`, so copying from scrollback never picks up glyphs
- Emacs key bindings with up/down prefix history search
- Terminal title updates (current dir / running command)
- `ls` is [eza](https://github.com/eza-community/eza) when installed: long table,
  directories first, icons, names with spaces not quoted. Otherwise plain
  colored `ls` (BSD `CLICOLOR` on macOS, `--color=auto` elsewhere)
- `COLORTERM=truecolor` restored over ssh when `$TERM` is Ghostty, kitty or
  a `*-direct` terminal (sshd drops the variable)
- Optional tools guarded — [zoxide](https://github.com/ajeetdsouza/zoxide),
  [fzf](https://github.com/junegunn/fzf), [eza](https://github.com/eza-community/eza), [nvm](https://github.com/nvm-sh/nvm),
  and `fortune` are used if present, silently skipped if not

## Aliases

`my-aliases` (sourced from `~/.my-aliases` if present) holds aliases for git,
docker, networking, etc. It builds on the base `ls` alias defined in `zshrc`.

Listing files:

| Alias | With eza | Without eza |
|---|---|---|
| `l` | names only, grid | names only, one per line |
| `ls` | long table | short grid |
| `ll` | long + hidden + group + git status | long |
| `la` | long + hidden | short + hidden |
| `lt` | all files by time, newest last | same |
| `lss` | by size, biggest last | by size, biggest first |
| `ltree` | two-level tree with git status | not defined |

SSH port forwarding (same port on both ends):

```bash
fip myserver 3000 8080   # localhost:3000 and :8080 now reach myserver
lip                      # list active forwards
dip 3000                 # stop one
```

Also: `..` / `...` / `....` to go up one, two or three directories.

## bash/

Unmodified copy of [Omarchy](https://omarchy.org)'s default bash config, kept
for reference. Nothing here is sourced by `zshrc`; useful pieces get ported
into `zshrc` or `my-aliases`.

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
