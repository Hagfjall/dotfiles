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
  # 1. Check current environment
  if [ "${XDG_SESSION_TYPE:-}" = "wayland" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
    echo "wayland"
    return
  fi

  # 2. If running under sudo, check the original user's session via loginctl
  if [ -n "${SUDO_USER:-}" ] && command -v loginctl >/dev/null 2>&1; then
    # Get the session type for the user who invoked sudo
    if loginctl list-sessions | grep -q " ${SUDO_USER} "; then
        # Try to find a wayland session for this user
        local session_ids
        session_ids=$(loginctl list-sessions | grep " ${SUDO_USER} " | awk '{print $1}')
        for id in $session_ids; do
            if [ "$(loginctl show-session "$id" -p Type --value 2>/dev/null)" = "wayland" ]; then
                echo "wayland"
                return
            fi
        done
    fi
  fi

  # 3. Check for Wayland socket in /run/user/UID as a fallback
  local user_id
  user_id=$(id -u "${SUDO_USER:-$(whoami)}")
  if [ -d "/run/user/${user_id}" ] && find "/run/user/${user_id}" -maxdepth 1 -name "wayland-*" -type s 2>/dev/null | grep -q .; then
    echo "wayland"
    return
  fi

  echo "x11"
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
      lm-sensors
    )
    echo -e "${BLUE}Installing Wayland display switcher dependencies...${NC}"
else
    # X11 packages
    packages=(
      rofi
      x11-xserver-utils
      libnotify-bin
      lm-sensors
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
        xrandr --versionXDG_SESSION_TYPE
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
