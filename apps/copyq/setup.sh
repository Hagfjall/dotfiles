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

log() {
  printf '[copyq-setup] %s\n' "$*" >&2
}

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${YELLOW}=== CopyQ Configuration Setup ===${NC}"
echo ""

# Check if CopyQ is installed
if ! have_package "copyq"; then
    echo -e "${RED}Error: CopyQ is not installed${NC}"
    echo ""
    echo "Please run the installation script first:"
    echo "  sudo $SCRIPT_DIR/install.sh"
    exit 1
fi

# Determine config directories
CONFIG_DIR="$HOME/.config/copyq"
AUTOSTART_DIR="$HOME/.config/autostart"
CONF_FILE="$CONFIG_DIR/copyq.conf"
AUTOSTART_FILE="$AUTOSTART_DIR/copyq.desktop"

echo -e "${BLUE}Setting up CopyQ configuration...${NC}"
echo ""

# Create config directory
echo -e "${YELLOW}Creating configuration directory...${NC}"
mkdir -p "$CONFIG_DIR"
log "Created $CONFIG_DIR"

# Copy configuration file
if [ -f "$CONF_FILE" ]; then
    BACKUP_FILE="$CONF_FILE.backup.$(date +%Y-%m-%d_%H-%M-%S)"
    echo -e "${YELLOW}Existing configuration found, creating backup:${NC}"
    echo "  $BACKUP_FILE"
    cp "$CONF_FILE" "$BACKUP_FILE"
else
    echo -e "${YELLOW}No existing configuration, creating new one...${NC}"
fi

cp "$SCRIPT_DIR/copyq.conf" "$CONF_FILE"
log "Configuration file installed: $CONF_FILE"
echo -e "${GREEN}✓ Configuration installed${NC}"

# Create autostart directory
echo ""
echo -e "${YELLOW}Setting up autostart...${NC}"
mkdir -p "$AUTOSTART_DIR"

# Create autostart desktop entry
cat > "$AUTOSTART_FILE" << 'EOF'
[Desktop Entry]
Type=Application
Name=CopyQ
Comment=Clipboard Manager
Exec=copyq
Icon=copyq
Terminal=false
Categories=Utility;
X-GNOME-Autostart-enabled=true
EOF

log "Autostart entry created: $AUTOSTART_FILE"
echo -e "${GREEN}✓ Autostart configured${NC}"

# Kill any running CopyQ instances
echo ""
echo -e "${YELLOW}Restarting CopyQ service...${NC}"
if have_command copyq; then
    killall copyq 2>/dev/null || true
    sleep 1
fi

# Start CopyQ in the background
copyq &>/dev/null &
sleep 2
if pgrep -q copyq; then
    log "CopyQ started successfully"
    echo -e "${GREEN}✓ CopyQ is now running${NC}"
else
    echo -e "${YELLOW}⚠ CopyQ started but may not be fully initialized${NC}"
    echo "  You can start it manually with: copyq"
fi

echo ""
echo "  Config file:     $CONF_FILE"
echo "  Autostart entry: $AUTOSTART_FILE"
echo "  History size:    200 items"
echo "  Hotkey:          Ctrl+Shift+V (show/hide clipboard history)"
echo "  Paste clean:     Ctrl+Shift+P (paste without formatting)"
echo ""

echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo -e "${YELLOW}Usage:${NC}"
echo "  • Press Ctrl+C to copy items (normal)"
echo "  • Press Ctrl+Shift+V to open clipboard history"
echo "  • Click on any item to paste it"
echo "  • Press Ctrl+Shift+P to paste without formatting"
echo "  • Press Ctrl+Alt+A to show action menu"
echo ""

echo -e "${YELLOW}Regolith Integration:${NC}"
# Check if Regolith is configured
if [ -d "$HOME/.config/regolith3" ]; then
    echo "  Detected Regolith configuration"
    echo "  Running Regolith integration setup..."
    echo ""

    # Run the Regolith integration script
    if [ -f "$SCRIPT_DIR/regolith-setup.sh" ]; then
        bash "$SCRIPT_DIR/regolith-setup.sh"
    fi
else
    echo "  Regolith not detected, skipping Regolith integration"
    echo "  If you use Regolith, run: ./regolith-setup.sh"
fi

echo ""
echo -e "${YELLOW}Next:${NC}"
echo "  CopyQ will automatically start on your next login"
echo "  To manually start CopyQ: copyq"
echo "  To stop CopyQ: killall copyq"
echo ""
