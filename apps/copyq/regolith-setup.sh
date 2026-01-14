#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
  printf '[copyq-regolith-setup] %s\n' "$*" >&2
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${YELLOW}=== CopyQ Regolith Integration Setup ===${NC}"
echo ""

# Check if Regolith is being used
if [[ ! -d "$HOME/.config/regolith3" ]]; then
    echo -e "${YELLOW}⚠ Regolith configuration directory not found${NC}"
    echo "  Install this integration manually if you're using Regolith"
    echo ""
    exit 0
fi

# Create sway config.d directory if it doesn't exist
SWAY_CONFIG_DIR="$HOME/.config/regolith3/sway/config.d"
mkdir -p "$SWAY_CONFIG_DIR"
log "Created sway config directory: $SWAY_CONFIG_DIR"

# Install sway keybinding config
SWAY_CONFIG_FILE="$SWAY_CONFIG_DIR/30-copyq.conf"
if [ -f "$SWAY_CONFIG_FILE" ]; then
    BACKUP_FILE="$SWAY_CONFIG_FILE.backup.$(date +%Y-%m-%d_%H-%M-%S)"
    echo -e "${YELLOW}Existing sway config found, creating backup:${NC}"
    echo "  $BACKUP_FILE"
    cp "$SWAY_CONFIG_FILE" "$BACKUP_FILE"
fi

cp "$SCRIPT_DIR/regolith-config.d-copyq.conf" "$SWAY_CONFIG_FILE"
log "Installed sway keybinding config: $SWAY_CONFIG_FILE"
echo -e "${GREEN}✓ Sway keybindings configured${NC}"

echo ""
echo -e "${BLUE}Keybindings Added:${NC}"
echo "  Super+C           - Show CopyQ history"
echo "  Super+Shift+V     - Paste without formatting"
echo "  Super+Ctrl+C      - Clear clipboard history"
echo ""

# Optional: Set up status bar integration
echo -e "${YELLOW}Status Bar Integration${NC}"
echo "  To add CopyQ to your i3status-rs bar, you can:"
echo ""
echo "  1. Edit: ~/.config/regolith3/i3status-rust/config.toml"
echo ""
echo "  2. Add this custom block (requires status-bar restart):"
echo ""
cat << 'EOF'
[[block]]
command = "$HOME/.local/share/copyq/regolith-status-bar.sh"
interval = 2
on_click = "copyq show"
EOF
echo ""

# Create the status bar script link location
STATUS_SCRIPT_DIR="$HOME/.local/share/copyq"
mkdir -p "$STATUS_SCRIPT_DIR"
cp "$SCRIPT_DIR/regolith-status-bar.sh" "$STATUS_SCRIPT_DIR/regolith-status-bar.sh"
chmod +x "$STATUS_SCRIPT_DIR/regolith-status-bar.sh"
log "Installed status bar script: $STATUS_SCRIPT_DIR/regolith-status-bar.sh"

echo -e "${GREEN}✓ Status bar script installed${NC}"

echo ""
echo -e "${GREEN}✓ Regolith integration complete!${NC}"
echo ""

echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo "1. Reload Regolith configuration:"
echo "   Super+Shift+C  (reload sway config)"
echo ""
echo "2. Test the keybindings:"
echo "   Super+C        (show clipboard history)"
echo "   Super+Shift+V  (paste without formatting)"
echo ""
echo "3. Optional: Add CopyQ to status bar"
echo "   Edit: ~/.config/regolith3/i3status-rust/config.toml"
echo "   Add the custom block shown above"
echo "   Then restart the status bar"
echo ""
