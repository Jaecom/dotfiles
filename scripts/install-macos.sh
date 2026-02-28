#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_DIR="$DOTFILES_DIR/config"

echo "=== macOS Full Setup ==="

# 1. Install Homebrew
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "Homebrew already installed."
fi

# 2. Install iTerm2
if ! brew list --cask iterm2 &>/dev/null; then
  echo "Installing iTerm2..."
  brew install --cask iterm2
else
  echo "iTerm2 already installed."
fi

# 3. Restore iTerm2 preferences
echo "Restoring iTerm2 preferences..."
cp "$CONFIG_DIR/com.googlecode.iterm2.plist" ~/Library/Preferences/com.googlecode.iterm2.plist

# 4. Install Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "Oh My Zsh already installed."
fi

# 5. Install Powerlevel10k theme
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
  echo "Installing Powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
  echo "Powerlevel10k already installed."
fi

# 6. Symlink dotfiles
echo "Symlinking .zshrc..."
ln -sf "$CONFIG_DIR/.zshrc" ~/.zshrc

echo "Symlinking .p10k.zsh..."
ln -sf "$CONFIG_DIR/.p10k.zsh" ~/.p10k.zsh

# 7. Symlink Claude config
echo "Symlinking Claude config..."
mkdir -p ~/.claude/scripts
ln -sf "$CONFIG_DIR/.claude/settings.json" ~/.claude/settings.json
ln -sf "$CONFIG_DIR/.claude/scripts/context-bar.sh" ~/.claude/scripts/context-bar.sh
for skill_dir in "$CONFIG_DIR"/.claude/skills/*/; do
  skill_name=$(basename "$skill_dir")
  mkdir -p ~/.claude/skills/"$skill_name"
  ln -sf "$skill_dir"SKILL.md ~/.claude/skills/"$skill_name"/SKILL.md
done

# 8. Install nvm
if [ ! -d "$HOME/.nvm" ]; then
  echo "Installing nvm..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
else
  echo "nvm already installed."
fi

# 9. Install Neovim config
NVIM_DIR="$HOME/.config/nvim"
if [ ! -d "$NVIM_DIR" ]; then
  echo "Cloning Neovim config..."
  mkdir -p "$HOME/.config"
  git clone https://github.com/Jaecom/nvim.git "$NVIM_DIR"
else
  echo "Neovim config already installed."
fi

# 10. Install pnpm
if ! command -v pnpm &>/dev/null; then
  echo "Installing pnpm..."
  curl -fsSL https://get.pnpm.io/install.sh | sh -
else
  echo "pnpm already installed."
fi

echo ""
echo "=== macOS setup complete! ==="
echo "Restart your terminal or run: source ~/.zshrc"
