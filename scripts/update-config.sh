#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_DIR="$DOTFILES_DIR/config"

[[ -z "$DOTFILES_QUIET" ]] && echo "=== Update Config Files ==="

# iTerm2 preferences
echo "Copying iTerm2 preferences..."
cp "$CONFIG_DIR/com.googlecode.iterm2.plist" ~/Library/Preferences/com.googlecode.iterm2.plist

# Symlink dotfiles
echo "Symlinking .zshrc..."
ln -sf "$CONFIG_DIR/.zshrc" ~/.zshrc

echo "Symlinking .p10k.zsh..."
ln -sf "$CONFIG_DIR/.p10k.zsh" ~/.p10k.zsh

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

# VS Code settings
VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
if [ -d "$VSCODE_USER_DIR" ]; then
  echo "Symlinking VS Code settings..."
  ln -sf "$CONFIG_DIR/vscode/settings.json" "$VSCODE_USER_DIR/settings.json"
  ln -sf "$CONFIG_DIR/vscode/keybindings.json" "$VSCODE_USER_DIR/keybindings.json"
fi

if [[ -z "$DOTFILES_QUIET" ]]; then
  echo ""
  echo "=== Config files updated! ==="
  echo "Restart your terminal or run: source ~/.zshrc"
fi
