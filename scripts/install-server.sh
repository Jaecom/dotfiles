#!/bin/bash

echo "=== Server Setup ==="

# Install Neovim config
NVIM_DIR="$HOME/.config/nvim"
if [ ! -d "$NVIM_DIR" ]; then
  echo "Cloning Neovim config..."
  mkdir -p "$HOME/.config"
  git clone https://github.com/Jaecom/nvim.git "$NVIM_DIR"
else
  echo "Neovim config already installed."
fi

echo ""
echo "=== Server setup complete! ==="
