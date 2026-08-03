#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_DIR="$DOTFILES_DIR/config"

[[ -z "$DOTFILES_QUIET" ]] && echo "=== Update Config Files ==="

# iTerm2 preferences
if brew list --cask iterm2 &>/dev/null; then
  echo "Copying iTerm2 preferences..."
  cp "$CONFIG_DIR/com.googlecode.iterm2.plist" ~/Library/Preferences/com.googlecode.iterm2.plist
fi

# Symlink dotfiles
echo "Symlinking .zshrc..."
ln -sf "$CONFIG_DIR/.zshrc" ~/.zshrc

echo "Symlinking .p10k.zsh..."
ln -sf "$CONFIG_DIR/.p10k.zsh" ~/.p10k.zsh

# Dialect for the sqlfluff formatter wired up in vscode/settings.json — without
# it sqlfluff defaults to ansi and flags ordinary Postgres syntax on every save.
echo "Symlinking .sqlfluff..."
ln -sf "$CONFIG_DIR/.sqlfluff" ~/.sqlfluff

# Symlink Claude config
echo "Symlinking Claude config..."
mkdir -p ~/.claude/scripts
ln -sf "$CONFIG_DIR/.claude/settings.json" ~/.claude/settings.json
ln -sf "$CONFIG_DIR/.claude/scripts/context-bar.sh" ~/.claude/scripts/context-bar.sh
for skill_dir in "$CONFIG_DIR"/.claude/skills/*/; do
  skill_name=$(basename "$skill_dir")
  mkdir -p ~/.claude/skills/"$skill_name"
  ln -sf "$skill_dir"SKILL.md ~/.claude/skills/"$skill_name"/SKILL.md
done

# Hammerspoon config — Accessibility and Bluetooth permissions must be granted
# manually via System Settings after first launch; macOS doesn't allow scripting that.
# Without Bluetooth access, blueutil (spawned as a child of Hammerspoon) aborts
# silently instead of prompting, so the JBL auto-connect in init.lua just times out.
echo "Symlinking Hammerspoon config..."
mkdir -p ~/.hammerspoon
ln -sf "$CONFIG_DIR/hammerspoon/init.lua" ~/.hammerspoon/init.lua
NEEDS_HAMMERSPOON_PERMISSIONS=1

# Karabiner config (copy instead of symlink — Karabiner rewrites this file and doesn't work with symlinks)
echo "Copying Karabiner config..."
mkdir -p ~/.config/karabiner
cp "$CONFIG_DIR/karabiner/karabiner.json" ~/.config/karabiner/karabiner.json

# Rectangle config (defaults import, not a symlink — macOS preference plists are
# owned by cfprefsd, which ignores a plain copy). Rectangle has to be stopped
# first: a running app is served cfprefsd's cached values and rewrites the whole
# domain when it quits, silently discarding the import.
# Note: import REPLACES the whole domain, so any Rectangle setting changed on
# this machine and not captured in the repo plist is discarded.
if [ -d "/Applications/Rectangle.app" ]; then
  echo "Importing Rectangle config..."
  RECTANGLE_RUNNING=""
  pkill -x Rectangle 2>/dev/null && RECTANGLE_RUNNING=1 && sleep 1
  defaults import com.knollsoft.Rectangle "$CONFIG_DIR/rectangle/com.knollsoft.Rectangle.plist"
  [ -n "$RECTANGLE_RUNNING" ] && open -a Rectangle
fi

# VS Code settings
VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
if [ -d "$VSCODE_USER_DIR" ]; then
  echo "Symlinking VS Code settings..."
  ln -sf "$CONFIG_DIR/vscode/settings.json" "$VSCODE_USER_DIR/settings.json"
  ln -sf "$CONFIG_DIR/vscode/keybindings.json" "$VSCODE_USER_DIR/keybindings.json"
fi

if [[ -n "$NEEDS_HAMMERSPOON_PERMISSIONS" ]]; then
  echo ""
  echo "ACTION NEEDED: grant Hammerspoon Accessibility and Bluetooth permission"
  echo "in System Settings > Privacy & Security (opening Bluetooth pane now)."
  open "x-apple.systempreferences:com.apple.preference.security?Privacy_Bluetooth" &>/dev/null
fi

if [[ -z "$DOTFILES_QUIET" ]]; then
  echo ""
  echo "=== Config files updated! ==="
  echo "Restart your terminal or run: source ~/.zshrc"
fi
