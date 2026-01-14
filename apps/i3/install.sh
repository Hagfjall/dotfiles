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

# Detect session type
detect_session() {
  if [ "${XDG_SESSION_TYPE:-}" = "wayland" ]; then
    echo "wayland"
  else
    echo "x11"
  fi
}

# Check if running with root privileges
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Error: This script must be run as root${NC}"
    echo "Please use: sudo $0"
    exit 1
fi

SESSION=$(detect_session)
echo -e "${YELLOW}=== Display Switcher Installation ===${NC}"
echo -e "${BLUE}Detected session: $SESSION${NC}"
echo ""

# Define packages based on session type
if [ "$SESSION" = "wayland" ]; then
    # Wayland packages
    packages=(
      rofi
      jq
      libnotify-bin
    )
    echo -e "${BLUE}Installing Wayland display switcher dependencies...${NC}"
else
    # X11 packages
    packages=(
      rofi
      x11-xserver-utils
      libnotify-bin
    )
    echo -e "${BLUE}Installing X11 display switcher dependencies...${NC}"
fi

echo ""

# Check if all packages are already installed
all_installed=true
for package in "${packages[@]}"; do
    if ! have_package "$package"; then
        all_installed=false
        break
    fi
done

if [ "$all_installed" = true ]; then
    echo -e "${GREEN}✓ All required packages are already installed${NC}"
    echo ""
    echo -e "${BLUE}Installation details:${NC}"
    rofi -version

    if [ "$SESSION" = "wayland" ]; then
        have_command swaymsg && swaymsg -v || echo "Sway version: (installed via system)"
        jq --version
    else
        xrandr --version
    fi
    echo ""
    exit 0
fi

echo -e "${YELLOW}Updating package list...${NC}"
apt-get update

missing_packages=()
for package in "${packages[@]}"; do
    if ! have_package "$package"; then
        missing_packages+=("$package")
    fi
done

if [ ${#missing_packages[@]} -gt 0 ]; then
    echo -e "${YELLOW}Installing missing packages: ${missing_packages[*]}...${NC}"
    if apt-get install -y "${missing_packages[@]}"; then
        echo -e "${GREEN}✓ Packages installed successfully${NC}"
    else
        echo -e "${RED}Error: Failed to install packages${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ All packages already installed${NC}"
fi

echo ""
echo -e "${BLUE}Installation details:${NC}"
rofi -version

if [ "$SESSION" = "wayland" ]; then
    have_command swaymsg && swaymsg -v || echo "Sway version: (installed via system)"
    jq --version
else
    xrandr --version
fi
echo ""

echo -e "${GREEN}✓ Installation complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Run: ./setup.sh"
echo "  2. This will configure the display switcher and set up the keyboard shortcut"
echo "  3. After setup, press Super+P to open the display mode selector"
echo ""
