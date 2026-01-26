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
  printf '[display-setup] %s\n' "$*" >&2
}

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${YELLOW}=== Display Switcher Configuration Setup ===${NC}"
echo ""

# Check if required packages are installed
if ! have_package "rofi"; then
    echo -e "${RED}Error: Required packages are not installed${NC}"
    echo ""
    echo "Please run the installation script first:"
    echo "  sudo $SCRIPT_DIR/install.sh"
    exit 1
fi

# Detect session type
SESSION="${XDG_SESSION_TYPE:-x11}"

# Determine directories
BIN_DIR="$HOME/.local/bin"

if [ "$SESSION" = "wayland" ]; then
    CONFIG_DIR="$HOME/.config/sway"
    CONFIG_FILE="$CONFIG_DIR/config"
    echo -e "${BLUE}Setting up display switcher for Wayland/Sway...${NC}"
else
    CONFIG_DIR="$HOME/.config/i3"
    CONFIG_FILE="$CONFIG_DIR/config"
    echo -e "${BLUE}Setting up display switcher for X11/i3...${NC}"
fi

# Regolith directory (try regolith3 first, then regolith)
if [ -d "$HOME/.config/regolith3" ]; then
    REGOLITH_DIR="$HOME/.config/regolith3"
else
    REGOLITH_DIR="$HOME/.config/regolith"
fi

echo ""

# Create bin directory
echo -e "${YELLOW}Creating bin directory...${NC}"
mkdir -p "$BIN_DIR"
log "Created $BIN_DIR"

# Install display switcher script
echo -e "${YELLOW}Installing display-switcher script...${NC}"
if [ -f "$SCRIPT_DIR/display-switcher.sh" ]; then
    cp "$SCRIPT_DIR/display-switcher.sh" "$BIN_DIR/display-switcher"
    chmod +x "$BIN_DIR/display-switcher"
    log "Installed: $BIN_DIR/display-switcher"
    echo -e "${GREEN}✓ Script installed${NC}"
else
    echo -e "${RED}Error: display-switcher.sh not found in $SCRIPT_DIR${NC}"
    exit 1
fi

# Configure i3/Sway with keybinding
echo ""
echo -e "${YELLOW}Configuring keyboard shortcut...${NC}"

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Backup existing config if it exists
if [ -f "$CONFIG_FILE" ]; then
    BACKUP_FILE="$CONFIG_FILE.backup.$(date +%Y-%m-%d_%H-%M-%S)"
    echo -e "${YELLOW}Existing config found, creating backup:${NC}"
    echo "  $BACKUP_FILE"
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    log "Backup created: $BACKUP_FILE"
else
    echo -e "${YELLOW}No existing config, creating new one...${NC}"
    # Try to find a default config to include
    DEFAULT_CONFIG=""
    if [ "$SESSION" = "wayland" ]; then
        if [ -f "/etc/regolith/sway/config" ]; then
            DEFAULT_CONFIG="/etc/regolith/sway/config"
        elif [ -f "/etc/sway/config" ]; then
            DEFAULT_CONFIG="/etc/sway/config"
        elif [ -f "/etc/xdg/sway/config" ]; then
            DEFAULT_CONFIG="/etc/xdg/sway/config"
        fi
    else
        # X11/i3 defaults
        if [ -f "/etc/regolith/i3/config" ]; then
            DEFAULT_CONFIG="/etc/regolith/i3/config"
        elif [ -f "/etc/i3/config" ]; then
            DEFAULT_CONFIG="/etc/i3/config"
        elif [ -f "/etc/xdg/i3/config" ]; then
            DEFAULT_CONFIG="/etc/xdg/i3/config"
        fi
    fi

    if [ -n "$DEFAULT_CONFIG" ]; then
        echo "include $DEFAULT_CONFIG" > "$CONFIG_FILE"
        echo "" >> "$CONFIG_FILE"
        log "Included default config: $DEFAULT_CONFIG"
    else
        # Minimal fallback
        echo "# Minimal config created by display-switcher setup" > "$CONFIG_FILE"
        echo "set \$mod Mod4" >> "$CONFIG_FILE"
        echo "font pango:monospace 8" >> "$CONFIG_FILE"
        echo "bindsym \$mod+Return exec x-terminal-emulator" >> "$CONFIG_FILE"
        echo "" >> "$CONFIG_FILE"
        log "Created minimal fallback config"
    fi
fi

# Check if keybinding already exists
if grep -q "display-switcher" "$CONFIG_FILE" 2>/dev/null; then
    echo -e "${GREEN}✓ Keybinding already configured${NC}"
    log "Display switcher keybinding already present in config"
else
    # Append keybinding
    echo ""
    cat >> "$CONFIG_FILE" << 'EOF'

# Display Switcher (WIN+P equivalent)
# Added by display-switcher setup
bindsym $mod+p exec --no-startup-id ~/.local/bin/display-switcher
EOF
    log "Keybinding added to config"
    echo -e "${GREEN}✓ Keybinding configured${NC}"
fi

# Reload configuration
echo ""
echo -e "${YELLOW}Reloading configuration...${NC}"
if [ "$SESSION" = "wayland" ]; then
    # Sway reload
    if have_command swaymsg; then
        if swaymsg reload >/dev/null 2>&1; then
            log "Sway configuration reloaded"
            echo -e "${GREEN}✓ Sway configuration reloaded${NC}"
        else
            echo -e "${YELLOW}⚠ Could not reload Sway automatically${NC}"
            echo "  You can manually reload with: swaymsg reload"
        fi
    else
        echo -e "${YELLOW}⚠ swaymsg not found, skipping reload${NC}"
        echo "  Reload Sway manually for changes to take effect"
    fi
else
    # i3 reload
    if have_command i3-msg; then
        if i3-msg reload >/dev/null 2>&1; then
            log "i3 configuration reloaded"
            echo -e "${GREEN}✓ i3 configuration reloaded${NC}"
        else
            echo -e "${YELLOW}⚠ Could not reload i3 automatically${NC}"
            echo "  You can manually reload with: i3-msg reload"
        fi
    else
        echo -e "${YELLOW}⚠ i3-msg not found, skipping reload${NC}"
        echo "  Reload i3 manually for changes to take effect"
    fi
fi

# Configure CPU Temperature Monitor
echo ""
echo -e "${YELLOW}Configuring CPU temperature monitor...${NC}"

if [ "$SESSION" = "wayland" ]; then
    # Wayland / i3status-rs setup
    I3STATUS_CONF_DIR="$REGOLITH_DIR/i3status-rust"
    mkdir -p "$I3STATUS_CONF_DIR"
    LOCAL_CONFIG="$I3STATUS_CONF_DIR/config.toml"

    # Copy default config if local doesn't exist
    if [ ! -f "$LOCAL_CONFIG" ]; then
        if [ -f "/etc/regolith/i3status-rust/config.toml" ]; then
            cp "/etc/regolith/i3status-rust/config.toml" "$LOCAL_CONFIG"
            log "Created local i3status-rs config from defaults"
        else
            echo -e "${RED}Error: perform i3status-rs setup failed, default config not found${NC}"
        fi
    fi

    # Insert custom block at the beginning (after theme/icons) if not already configured
    if [ -f "$LOCAL_CONFIG" ]; then
        if ! grep -q "get_cpu_temp.sh" "$LOCAL_CONFIG"; then
            # Temporary file to build the new config
            TEMP_CONF=$(mktemp)
            
            # Find the line number of the first [[block]]
            FIRST_BLOCK_LINE=$(grep -n "^\[\[block\]\]" "$LOCAL_CONFIG" | head -n 1 | cut -d: -f1)
            
            if [ -n "$FIRST_BLOCK_LINE" ]; then
                # Insert before the first block
                head -n "$((FIRST_BLOCK_LINE - 1))" "$LOCAL_CONFIG" > "$TEMP_CONF"
                echo "[[block]]" >> "$TEMP_CONF"
                echo "block = \"custom\"" >> "$TEMP_CONF"
                echo "command = \"$SCRIPT_DIR/get_cpu_temp.sh\"" >> "$TEMP_CONF"
                echo "interval = 10" >> "$TEMP_CONF"
                echo "" >> "$TEMP_CONF"
                tail -n +"$FIRST_BLOCK_LINE" "$LOCAL_CONFIG" >> "$TEMP_CONF"
                mv "$TEMP_CONF" "$LOCAL_CONFIG"
            else
                # No blocks yet, just append
                echo "" >> "$LOCAL_CONFIG"
                echo "[[block]]" >> "$LOCAL_CONFIG"
                echo "block = \"custom\"" >> "$LOCAL_CONFIG"
                echo "command = \"$SCRIPT_DIR/get_cpu_temp.sh\"" >> "$TEMP_CONF"
                echo "interval = 10" >> "$LOCAL_CONFIG"
            fi
            log "Inserted CPU temp block at the beginning of $LOCAL_CONFIG"
        else
            log "CPU temp block already exists in i3status-rs config"
        fi
    fi

    # Update Xresources to use the local config
    XRES_FILE="$REGOLITH_DIR/Xresources"
    if [ ! -f "$XRES_FILE" ]; then
        touch "$XRES_FILE"
    fi

    if ! grep -q "wm.bar.status_config: $LOCAL_CONFIG" "$XRES_FILE"; then
        # Remove old setting if exists (simple implementation)
        sed -i '/wm.bar.status_config/d' "$XRES_FILE"
        echo "wm.bar.status_config: $LOCAL_CONFIG" >> "$XRES_FILE"
        log "Updated Xresources to use local i3status-rs config"
        
        # Reload Xresources
        if have_command xrdb; then
            xrdb -merge "$XRES_FILE"
        fi
    fi
else
    # X11 / i3xrocks setup
    I3XROCKS_CONF_DIR="$REGOLITH_DIR/i3xrocks/conf.d"
    mkdir -p "$I3XROCKS_CONF_DIR"

    # Symlink config
    if [ -L "$I3XROCKS_CONF_DIR/01_cpu" ]; then
        log "CPU config symlink already exists"
    else
        # Remove old 80_cpu if it exists
        rm -f "$I3XROCKS_CONF_DIR/80_cpu"
        ln -sf "$SCRIPT_DIR/01_cpu.conf" "$I3XROCKS_CONF_DIR/01_cpu"
        log "Linked $I3XROCKS_CONF_DIR/01_cpu -> $SCRIPT_DIR/01_cpu.conf"
    fi
fi

# Ensure script is executable
chmod +x "$SCRIPT_DIR/get_cpu_temp.sh"
echo -e "${GREEN}✓ CPU temperature monitor configured${NC}"

echo ""
echo -e "${BLUE}Configuration details:${NC}"
echo "  Script location: $BIN_DIR/display-switcher"
echo "  Config file:     $CONFIG_FILE"
echo "  Keyboard:        Super+P (Win+P equivalent)"
echo ""

echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo -e "${YELLOW}Usage:${NC}"
echo "  Press Super+P to open the display mode selector"
echo "  Select your preferred display mode:"
echo "    • Laptop only       - Use only the laptop screen"
echo "    • External only     - Use only the external monitor"
echo "    • Extended desktop  - Use both (external right of laptop)"
echo ""
echo -e "${YELLOW}Advanced:${NC}"
echo "  To customize the display positioning, edit:"
echo "    ~/.local/bin/display-switcher"
echo ""
echo -e "${YELLOW}Troubleshooting:${NC}"
echo "  If something goes wrong, restore the backup:"
echo "    cp $BACKUP_FILE $CONFIG_FILE"
echo "    i3-msg reload"
echo ""
echo -e "${YELLOW}Detected displays:${NC}"
xrandr --query | grep " connected" | awk '{print "  " $1}'
echo ""
