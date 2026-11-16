#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
have_command() {
  command -v "$1" >/dev/null 2>&1
}

have_package() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd -P)"

echo -e "${YELLOW}=== less Syntax Highlighting Installation ===${NC}"
echo ""

# Packages to install: bat (Rust high speed highlighter), python3-pygments, highlight
packages_to_install=()

for pkg in bat python3-pygments highlight; do
  case "$pkg" in
    bat)
      if ! have_command bat && ! have_command batcat && ! have_package "bat"; then
        packages_to_install+=("bat")
      fi
      ;;
    python3-pygments)
      if ! have_command pygmentize && ! have_package "python3-pygments"; then
        packages_to_install+=("python3-pygments")
      fi
      ;;
    highlight)
      if ! have_command highlight && ! have_package "highlight"; then
        packages_to_install+=("highlight")
      fi
      ;;
  esac
done

if [ ${#packages_to_install[@]} -gt 0 ]; then
  echo -e "${BLUE}Installing highlighter packages (${packages_to_install[*]})...${NC}"
  if have_command apt-get; then
    sudo_cmd=""
    if [ "$(id -u)" -ne 0 ]; then
      if have_command sudo; then
        sudo_cmd="sudo"
      else
        echo -e "${RED}Error: sudo is required to install packages via apt-get${NC}"
        exit 1
      fi
    fi
    $sudo_cmd apt-get update
    $sudo_cmd apt-get install -y "${packages_to_install[@]}"
    echo -e "${GREEN}✓ Highlighter packages installed successfully${NC}"
  else
    echo -e "${RED}Error: apt-get not found. Please install bat, python3-pygments, or highlight manually.${NC}"
    exit 1
  fi
else
  echo -e "${GREEN}✓ Highlighter packages are already installed${NC}"
fi

echo ""
echo -e "${BLUE}Applying less configuration...${NC}"

target_home="${HOME}"
if [ -n "${SUDO_USER:-}" ] && [ "$(id -u)" -eq 0 ]; then
  uhome="$(getent passwd "$SUDO_USER" 2>/dev/null | cut -d: -f6)"
  if [ -n "$uhome" ]; then
    target_home="$uhome"
  fi
fi

bash "$SCRIPT_DIR/setup.sh" "$DOTFILES_DIR" "$target_home"

echo ""
echo -e "${GREEN}✓ less syntax highlighting setup complete!${NC}"
echo ""
