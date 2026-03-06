#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# Arrow-key menu selector
# Usage: select_option "prompt" option1 option2 ...
# Sets SELECTED_INDEX (0-based) on return
select_option() {
  local prompt="$1"
  shift
  local options=("$@")
  local selected=0
  local count=${#options[@]}

  # Hide cursor
  tput civis

  # Print header
  echo "$prompt"
  echo ""

  # Draw menu
  draw_menu() {
    for i in "${!options[@]}"; do
      tput el  # clear line
      if [[ $i -eq $selected ]]; then
        echo -e "  \033[1;36m❯ ${options[$i]}\033[0m"
      else
        echo "    ${options[$i]}"
      fi
    done
  }

  draw_menu

  # Read input
  while true; do
    read -rsn1 key
    case "$key" in
      $'\x1b')  # ESC sequence
        read -rsn2 seq
        case "$seq" in
          '[A')  # Up arrow
            ((selected = (selected - 1 + count) % count))
            ;;
          '[B')  # Down arrow
            ((selected = (selected + 1) % count))
            ;;
        esac
        ;;
      '')  # Enter
        break
        ;;
    esac
    # Move cursor back up to redraw
    tput cuu "$count"
    draw_menu
  done

  # Show cursor
  tput cnorm
  echo ""

  SELECTED_INDEX=$selected
}

echo "=== Dotfiles Setup ==="
echo ""

select_option "Select setup type:" \
  "Full macOS install" \
  "Update config files only" \
  "Server setup (Neovim config only)"

case "$SELECTED_INDEX" in
  0)
    bash "$DOTFILES_DIR/scripts/install-macos.sh"
    ;;
  1)
    bash "$DOTFILES_DIR/scripts/update-config.sh"
    ;;
  2)
    bash "$DOTFILES_DIR/scripts/install-server.sh"
    ;;
esac
