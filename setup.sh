#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Dotfiles Setup ==="
echo ""
echo "Select setup type:"
echo "  1) Full macOS install"
echo "  2) Server setup (Neovim config only)"
echo ""
read -p "Enter choice [1/2]: " choice

case "$choice" in
  1)
    bash "$DOTFILES_DIR/scripts/install-macos.sh"
    ;;
  2)
    bash "$DOTFILES_DIR/scripts/install-server.sh"
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac
