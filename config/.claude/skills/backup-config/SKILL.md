---
name: bc
description: Find Mac config that affects daily workflow but isn't captured in dotfiles — ranked list, approve by number, then add only what you approved
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
---

# Backup Config

Find the configuration that actually shapes how the user works every day and that the dotfiles repo does NOT yet reproduce on a fresh machine. Present a ranked, numbered list. The user approves items by number. You add only those.

**Do not change any file until the user has approved items from the list.**

The question to ask of every finding:

> If I set up a new Mac tomorrow from this repo alone, what would feel wrong, missing, or broken while I'm actually working?

If the answer is "nothing, I'd never notice" — it's noise. Drop it. **An exhaustive inventory of the machine is a failed result.** The goal is the short list of things that would actually bite.

## Phase 0: Locate the Repo

This skill runs on any machine, so **never hardcode a repo path or a home directory** — derive both. Resolve `$DOTFILES_DIR` with the first method that succeeds:

**1. Follow this skill's own symlink.** `update-config.sh` symlinks this file out of the repo, so the link points home:

```bash
LINK="$HOME/.claude/skills/backup-config/SKILL.md"
[ -L "$LINK" ] && DOTFILES_DIR=$(cd "$(dirname "$(readlink "$LINK")")/../../../.." && pwd)
```

**2. Walk up from the current directory.** Works when invoked inside the repo, or when the skill was copied rather than symlinked:

```bash
d=$PWD
while [ "$d" != "/" ]; do
  [ -f "$d/setup.sh" ] && [ -d "$d/config" ] && [ -d "$d/scripts" ] && DOTFILES_DIR=$d && break
  d=$(dirname "$d")
done
```

**3. Ask the user.** Do not guess, and do not fall back to a hardcoded location.

Validate the result before scanning — `$DOTFILES_DIR` must contain `setup.sh`, `config/`, and `scripts/`. Reference every repo file through `$DOTFILES_DIR` from here on, and every machine file through `$HOME`.

Then read all of these so you know what is already handled:

| File | Covers |
|------|--------|
| `setup.sh` | menu entry point |
| `scripts/install-macos.sh` | brew, casks, runtimes, VS Code extensions |
| `scripts/install-server.sh` | neovim + config + shell aliases (Linux-safe) |
| `scripts/update-config.sh` | symlinks and copies for every config file |
| `config/.zshrc`, `config/.p10k.zsh` | shell |
| `config/vscode/*` | settings, keybindings, extensions.txt |
| `config/karabiner/karabiner.json` | keyboard rules |
| `config/.claude/**` | settings, scripts, skills |
| `config/com.googlecode.iterm2.plist` | terminal |
| `config/rectangle/*.plist` | window snapping (`defaults import`) |
| `config/.sqlfluff` | SQL lint/format rules |

## Phase 1: Priority Model

Rank every finding into a tier. Tier drives the entire output.

- **T1** — Touches the user daily, or its absence silently breaks something. Linters and formatters and their on-save wiring, LSP settings, language toolchain binaries, shell aliases and functions, keybindings, git ergonomics, anything on PATH that nothing installs.
- **T2** — Touches them weekly, or is annoying-but-obvious when missing. GUI apps clearly in use, editor behavior settings, terminal setup, per-language editor blocks for languages they actually write.
- **T3** — Cosmetic or one-time. Themes, icon themes, color customizations, window chrome. At most a couple of collapsed lines total.
- **SKIP** — Machine-specific, auto-generated, or secret. Name it, never track it. Caches, state files, tokens, API keys, SSH keys, license strings, anything under a path containing a UUID or hostname.

## Phase 2: The Most Important Check — Broken Chains

Most of the real damage in a dotfiles repo is not a missing file. It's a half-captured chain — one link is tracked, the others aren't, so the config *looks* present but does nothing on a fresh machine.

A workflow chain is:

```
runtime installed → tool binary installed → tool config file →
editor extension → editor settings wiring it up → shell PATH/alias
```

Walk every chain end to end. Report the gap, not the inventory.

**Calibration.** These are open in this repo as of 2026-08-02. Verify each is still true — several have been closed since this skill was written — then go find the rest of this same shape:

- `.zshrc` puts `$HOME/.maestro/bin` and `$HOME/.local/bin` on PATH; nothing installs into either.
- `.zshrc` globs `$HOME/Library/Python/*/bin` onto PATH, but nothing in the repo pip-installs anything into it. The binaries actually living there on this machine (pytest, diff-cover) are untracked.
- `~/.gitconfig` is not tracked at all, so aliases, `core.excludesfile` and the global gitignore it points at don't survive a rebuild.
- `.zshrc` loads `plugins=(git)` only, and nothing installs zsh plugins — no autosuggestions, no syntax highlighting.

The shape to look for: **the config half is tracked and the install half isn't** (or the reverse). The Go chain used to be the worst offender here — `[go]` settings with no `golang.go` extension and no `gopls` — and fixing it took four files at once. Expect the next one to look just as innocuous.

Run the check in both directions:

- **Forward** — repo config references a tool → is that tool installed by the repo? Every extension in `extensions.txt` needing a companion binary, every `settings.json` key naming a formatter or language server, every PATH entry in `.zshrc`, every alias pointing at an absolute path.
- **Reverse** — a tool is installed and clearly in use → is its config captured? A linter on this machine whose config the repo doesn't track is **T1**, because lint rules *are* the workflow.

## Phase 3: Scan by Workflow Area

Skip anything failing the "would I notice?" test. Depth beats breadth — go deep on these, don't pad.

### Linting, formatting, language servers (highest value — start here)

For every language actually written on this machine, determine all four links: is the binary installed, is there a config file and where, does the editor know about it, does the repo install and track all of it.

- **Go** — `golangci-lint` (+ `.golangci.yml` anywhere in usual project dirs), gopls settings, gofumpt, goimports, staticcheck, dlv, `go env GOPATH GOBIN GOPRIVATE GOFLAGS GOPROXY`, contents of `$(go env GOPATH)/bin`
- **Node/TS** — eslint, prettier (+ `~/.prettierrc*`, `~/.editorconfig`), biome, typescript pinning, pnpm/npm globals
- **Python** — ruff, black, mypy, pyright, isort and their configs; which python is actually default vs what the alias claims
- **Shell** — shellcheck, shfmt
- Any global lint config living only on this machine is **T1**. Those rules decide what the editor complains about all day.

### Editor behavior (not theming)

`settings.json` and `keybindings.json` are symlinked by `update-config.sh` — **verify with `ls -l` first**, and if the links are intact there's no drift to report. If replaced by real files, diff and separate:

- behavior keys (formatters, `formatOnSave`, `codeActionsOnSave`, `[lang]` blocks, autoSave, LSP settings) → T1/T2, report individually
- theming keys (`colorCustomizations`, `iconTheme`, `colorTheme`) → T3, one collapsed line

Every custom keybinding is muscle memory: **T1**. Also check extensions installed but missing from `extensions.txt`, judging each — language extension is T1, theme is T3, installed-once-never-used is SKIP.

### Shell ergonomics

`.zshrc` and `.p10k.zsh` are symlinked — verify with `ls -l`, and if intact don't report them as drift. What is *not* tracked and matters:

- `~/.zprofile`, `~/.zshenv`, `~/.bashrc` — any real PATH exports, aliases, or tool init living outside the tracked `.zshrc`
- oh-my-zsh plugins: `.zshrc` currently loads only `plugins=(git)`. Check `${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins` for anything installed but not enabled, and call out everyday-use ones absent entirely (zsh-autosuggestions, zsh-syntax-highlighting, fzf, zoxide, direnv). These are T1 typing-experience items — note that `update-config.sh` installs no zsh plugins at all today.
- aliases and functions defined outside the tracked `.zshrc`
- history config, key bindings, completion setup

### Git everyday use

`~/.gitconfig` is not tracked at all. Report as separate items: aliases, default branch, `pull.rebase`, `push.autoSetupRemote`, rerere, pager/delta setup, commit template, `core.excludesfile` and the global gitignore it points at, credential helper (name only, never the value). Global gitignore and git aliases are **T1** — they change every commit.

### Keyboard and shortcuts

- `~/.config/karabiner/karabiner.json` vs `config/karabiner/karabiner.json`. This is **copied, not symlinked**, so it drifts silently in both directions. Diff the rule sets and describe what changed behaviorally ("new hyper-key rule", not "3 lines differ"). T1.
- macOS app shortcut overrides: `defaults read NSGlobalDomain NSUserKeyEquivalents`, plus per-app domains
- Key repeat rate, initial key repeat, press-and-hold, fn-key behavior — **T1**, wrong key repeat is felt within ten seconds of use
- Any launcher/hotkey tool (Raycast, Alfred, Rectangle, Hammerspoon) and whether its config is captured. Its keybindings *are* the workflow.

### Toolchain and apps

`brew leaves` and `brew list --cask`. **Do not dump the whole list.** Report only what `install-macos.sh` doesn't install, and make the daily-use judgment on each: a CLI clearly in use is T1/T2, a one-off dependency is SKIP. Same for pnpm/npm globals and `$(go env GOPATH)/bin` binaries. Resolve the Homebrew prefix with `$(brew --prefix)` rather than assuming `/opt/homebrew` — it's `/usr/local` on Intel Macs.

### Claude Code

`config/.claude/**` is symlinked — verify, then look for what's untracked: `~/.claude/CLAUDE.md`, `keybindings.json`, `agents/`, `commands/`, and any skill in `~/.claude/skills` not in `config/.claude/skills`. Global CLAUDE.md and custom skills shape every session: **T1**.

### Terminal

`com.googlecode.iterm2.plist` is copied, not symlinked — it drifts. Only report it if something *behavioral* changed (keybindings, shell integration, scrollback, fonts). Ignore diffs caused purely by window position or state keys.

## Phase 4: Output Format

Numbered list, T1 block first, then T2, then a collapsed T3 block. Group by area within each tier. One item per line:

```
T1
 1. [CHAIN] Go toolchain is configured but never installed
    settings.json wires up gopls + gofumpt + organizeImports, but golang.go is
    missing from extensions.txt and no Go tools are installed.
    → config/vscode/extensions.txt (add golang.go)
    → scripts/install-macos.sh (go install gopls, gofumpt, dlv)

 2. [ADD] Global gitignore + git aliases are untracked
    ~/.gitconfig has 6 aliases and points core.excludesfile at
    ~/.gitignore_global, neither of which exist in this repo.
    → new config/.gitconfig + config/.gitignore_global
    → scripts/update-config.sh (symlink both)

T3
18-22. [ADD] 5 theme/icon extensions not in extensions.txt (collapsed)
    → config/vscode/extensions.txt
```

Rules:

- Tags: `[CHAIN]` broken dependency chain, `[ADD]` on machine not in repo, `[DRIFT]` copied file diverged, `[STALE]` in repo but gone from machine
- **`[CHAIN]` items outrank everything else. Lead with them.**
- Every item names its exact destination file, and says when a section, file, or script doesn't exist yet
- Say what the thing *does*, not that it exists. "adds a hyper-key rule" beats "karabiner.json differs"
- Mark genuinely ambiguous items with `?` and one clause on the doubt
- No prose paragraphs. If T1 runs past ~15 items you're including noise — re-apply the "would I notice?" test and cut
- Do **not** use AskUserQuestion here. The list is too long for it; plain numbered text is the interface

Then **STOP and wait.** The user replies with numbers, e.g. `1, 4, 7-9, 15`.

## Phase 5: Apply Only What Was Approved

- Put each item in the destination file named in the list, matching that file's existing style exactly. The install scripts use `if ! command -v x` / `if [ ! -d ... ]` guards with an `echo "already installed"` else branch — follow that, don't invent a new pattern.
- **Fix chains completely or not at all.** An approved linter means the binary install, its config file, the editor extension, and the settings wiring — all of it. A half-applied chain is the exact bug this skill exists to find; don't recreate it.
- `install-server.sh` must stay Linux-safe. Nothing brew-only or macOS-only.
- Any **new** config file also needs a symlink or copy line in `update-config.sh`, or it will never reach a fresh machine.
- Prefer symlinks. Use a copy only for files the owning app rewrites (karabiner, iterm2) and say why in a comment.
- Keep existing sort order in `extensions.txt` and similar list files.
- Do not reformat, reorder, or clean up anything not approved.

When done:

1. Run `bash -n` on every script touched.
2. Show `git diff --stat`.
3. State in a few lines what went in, what was declined, and any chain left half-open because only part of it was approved.
4. **Do not commit.** The user reviews and commits.
