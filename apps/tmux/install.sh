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

echo -e "${YELLOW}=== tmux Installation & Configuration ===${NC}"
echo ""

if ! have_package "tmux" && ! have_command tmux; then
  echo -e "${BLUE}Installing tmux package...${NC}"
  if have_command apt-get; then
    sudo_cmd=""
    if [ "$(id -u)" -ne 0 ]; then
      if have_command sudo; then
        sudo_cmd="sudo"
      else
        echo -e "${RED}Error: sudo is required to install tmux via apt-get${NC}"
        exit 1
      fi
    fi
    $sudo_cmd apt-get update
    $sudo_cmd apt-get install -y tmux
    echo -e "${GREEN}✓ tmux package installed successfully${NC}"
  else
    echo -e "${RED}Error: apt-get not found. Please install tmux manually.${NC}"
    exit 1
  fi
else
  echo -e "${GREEN}✓ tmux is already installed${NC}"
fi

echo ""
echo -e "${BLUE}Applying tmux configuration...${NC}"

target_home="${HOME}"
if [ -n "${SUDO_USER:-}" ] && [ "$(id -u)" -eq 0 ]; then
  uhome="$(getent passwd "$SUDO_USER" 2>/dev/null | cut -d: -f6)"
  if [ -n "$uhome" ]; then
    target_home="$uhome"
  fi
fi

bash "$SCRIPT_DIR/setup.sh" "$DOTFILES_DIR" "$target_home"

echo ""
echo -e "${GREEN}✓ tmux setup complete!${NC}"
echo -e "Version: $(tmux -V 2>/dev/null || echo 'unknown')"
echo ""
echo -e "${YELLOW}Key features:${NC}"
echo "  • New windows (Prefix + c) open in current pane's directory"
echo "  • Split panes (Prefix + % / | / \\ / \" / - / _) open in current pane's directory"
echo "  • Reload config in tmux: Prefix + r"
echo ""
