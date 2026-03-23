#!/bin/bash

[[ -z "$DOTFILES_QUIET" ]] && echo "=== Server Setup ==="

# Install Neovim
if ! command -v nvim &>/dev/null; then
  echo "Installing Neovim..."
  if command -v brew &>/dev/null; then
    brew install neovim
  else
    ARCH=$(uname -m)
    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
      NVIM_ARCHIVE="nvim-linux-arm64"
    else
      NVIM_ARCHIVE="nvim-linux-x86_64"
    fi
    curl -fLo /tmp/"$NVIM_ARCHIVE".tar.gz https://github.com/neovim/neovim/releases/download/stable/"$NVIM_ARCHIVE".tar.gz
    tar xzf /tmp/"$NVIM_ARCHIVE".tar.gz -C /tmp
    sudo rm -rf /opt/nvim
    sudo mv /tmp/"$NVIM_ARCHIVE" /opt/nvim
    sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
    rm /tmp/"$NVIM_ARCHIVE".tar.gz
  fi
else
  echo "Neovim already installed."
fi

# Install Neovim config
NVIM_DIR="$HOME/.config/nvim"
if [ ! -d "$NVIM_DIR" ]; then
  echo "Cloning Neovim config..."
  mkdir -p "$HOME/.config"
  git clone https://github.com/Jaecom/nvim.git "$NVIM_DIR"
else
  echo "Neovim config already installed."
fi

# Add vim alias and sudo alias expansion to point to nvim
for SHELL_RC in "$HOME/.bashrc" "$HOME/.zshrc"; do
  if [ -f "$SHELL_RC" ]; then
    if ! grep -q 'alias vim=.*nvim' "$SHELL_RC" 2>/dev/null; then
      echo "Adding vim → nvim alias to $SHELL_RC..."
      echo 'alias vim="nvim"' >> "$SHELL_RC"
    else
      echo "vim → nvim alias already set in $SHELL_RC."
    fi
    if ! grep -q "alias sudo='sudo '" "$SHELL_RC" 2>/dev/null; then
      echo "Adding sudo alias expansion to $SHELL_RC..."
      echo "alias sudo='sudo '" >> "$SHELL_RC"
    else
      echo "sudo alias expansion already set in $SHELL_RC."
    fi
  fi
done

if [[ -z "$DOTFILES_QUIET" ]]; then
  echo ""
  echo "=== Server setup complete! ==="
  echo "Restart your shell or run: source $SHELL_RC"
fi
