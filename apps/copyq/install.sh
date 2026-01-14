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

# Check if running with root privileges
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Error: This script must be run as root${NC}"
    echo "Please use: sudo $0"
    exit 1
fi

echo -e "${YELLOW}=== CopyQ Clipboard Manager Installation ===${NC}"
echo ""

# Check if CopyQ is already installed
if have_package "copyq"; then
    echo -e "${GREEN}✓ CopyQ is already installed${NC}"
    copyq --version
    exit 0
fi

echo -e "${BLUE}Installing CopyQ clipboard manager...${NC}"
echo ""

# Update package list
echo -e "${YELLOW}Updating package list...${NC}"
apt-get update

# Install CopyQ
echo -e "${YELLOW}Installing copyq package...${NC}"
if apt-get install -y copyq; then
    echo -e "${GREEN}✓ CopyQ installed successfully${NC}"
else
    echo -e "${RED}Error: Failed to install CopyQ${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Installation details:${NC}"
copyq --version
echo ""

echo -e "${GREEN}✓ Installation complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Run: ./setup.sh"
echo "  2. This will configure CopyQ and set it to start automatically"
echo "  3. After restart, press Ctrl+Shift+V to open clipboard history"
echo ""
