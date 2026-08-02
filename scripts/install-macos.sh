#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== macOS Full Setup ==="

# Install helpers — each is idempotent and reports what it skipped.
#
# Formulas are checked with `brew list`, never `command -v`: macOS ships stub
# binaries that answer `command -v` with nothing installed behind them
# (/usr/bin/java, /usr/bin/javac and /usr/libexec/java_home are one shared stub).
brew_formula() {
  if brew list "$1" &>/dev/null; then
    echo "$1 already installed."
  else
    echo "Installing $1..."
    brew install "$1"
  fi
}

# brew_cask <cask> <app bundle path>
brew_cask() {
  local name=${2##*/}
  if [ -d "$2" ]; then
    echo "${name%.app} already installed."
  else
    echo "Installing ${name%.app}..."
    brew install --cask "$1"
  fi
}

# go_tool <binary> <module@version> — checked by path, since GOBIN is not on
# PATH during a fresh install.
go_tool() {
  if [ -x "$GOBIN/$1" ]; then
    echo "$1 already installed."
  else
    echo "Installing $1..."
    go install "$2"
  fi
}

# 1. Homebrew
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "Homebrew already installed."
fi

# 2. Terminal and shell
brew_cask iterm2 "/Applications/iTerm.app"

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "Oh My Zsh already installed."
fi

P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
  echo "Installing Powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
  echo "Powerlevel10k already installed."
fi

# 3. Node.js via nvm
if [ ! -d "$HOME/.nvm" ]; then
  echo "Installing nvm..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
else
  echo "nvm already installed."
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
if command -v nvm &>/dev/null; then
  # Match a real version line (`->  v22.11.0`). Every other line `nvm ls` prints
  # is an alias arrow or N/A, so filtering those out instead leaves nothing
  # behind on a machine with one version and no system node.
  if nvm ls --no-colors 2>/dev/null | grep -qE '^[ >*-]*v[0-9]+\.'; then
    echo "Node.js already installed via nvm."
  else
    echo "Installing Node.js (LTS)..."
    nvm install --lts
    nvm alias default 'lts/*'
  fi
fi

if ! command -v pnpm &>/dev/null; then
  echo "Installing pnpm..."
  curl -fsSL https://get.pnpm.io/install.sh | sh -
else
  echo "pnpm already installed."
fi

# 4. Language toolchains
# Pinned to the LTS JDK — Gradle and Maestro lag the newest OpenJDK release.
brew_formula openjdk@21
# openjdk@21 is keg-only, so link the bundle where /usr/libexec/java_home (and
# therefore .zshrc's JAVA_HOME) can find it.
JDK_BUNDLE="$(brew --prefix openjdk@21 2>/dev/null)/libexec/openjdk.jdk"
if [ -d "$JDK_BUNDLE" ] && [ ! -e "/Library/Java/JavaVirtualMachines/openjdk-21.jdk" ]; then
  echo "Registering OpenJDK 21 with java_home (needs sudo)..."
  sudo mkdir -p /Library/Java/JavaVirtualMachines
  sudo ln -sfn "$JDK_BUNDLE" "/Library/Java/JavaVirtualMachines/openjdk-21.jdk"
fi

brew_formula go
brew_formula postgresql@18
brew_formula cocoapods
# SQL linter behind the [sql] formatter in config/vscode/settings.json
brew_formula sqlfluff

# Go tools (LSP + live reload)
if command -v go &>/dev/null; then
  export GOBIN="$(go env GOPATH)/bin"
  go_tool gopls golang.org/x/tools/gopls@latest
  go_tool air github.com/air-verse/air@latest
fi

# 5. Apps
brew_cask karabiner-elements "/Applications/Karabiner-Elements.app"
brew_cask visual-studio-code "/Applications/Visual Studio Code.app"
brew_cask google-chrome "/Applications/Google Chrome.app" # required by `ch` (claude --chrome)
brew_cask rectangle "/Applications/Rectangle.app"         # prefs restored by update-config.sh
brew_cask raycast "/Applications/Raycast.app"             # settings are cloud-synced
brew_cask gitkraken "/Applications/GitKraken.app"
brew_cask notion "/Applications/Notion.app"

# 6. VS Code extensions
if command -v code &>/dev/null; then
  echo "Installing VS Code extensions..."
  while IFS= read -r ext; do
    [ -n "$ext" ] && code --install-extension "$ext" --force &>/dev/null
  done < "$DOTFILES_DIR/config/vscode/extensions.txt"

  # Dropping a line from extensions.txt can't uninstall anything, so removals
  # have to be named explicitly.
  INSTALLED_EXTS=$(code --list-extensions)
  for ext in github.copilot github.copilot-chat; do
    if grep -qix "$ext" <<<"$INSTALLED_EXTS"; then
      echo "Removing $ext..."
      code --uninstall-extension "$ext" &>/dev/null
    fi
  done
fi

# 7. Neovim config
DOTFILES_QUIET=1 bash "$DOTFILES_DIR/scripts/install-server.sh"

# 8. Config files
DOTFILES_QUIET=1 bash "$DOTFILES_DIR/scripts/update-config.sh"

echo ""
echo "=== macOS setup complete! ==="
