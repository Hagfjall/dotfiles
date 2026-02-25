#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTOSTART_CONF="$SCRIPT_DIR/autostart.conf"

# Helper to check if string exists in file
grep_q() {
    grep -q "$1" "$2"
}

# Detect Sway (priority since regolith3/Sway seems active)
if command -v swaymsg >/dev/null && [ -d "$HOME/.config/sway" ]; then
    echo "Sway config detected (~/.config/sway)."
    CONFIG_FILE="$HOME/.config/sway/config"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Creating minimal Sway config..."
        echo "include /etc/regolith/sway/config" > "$CONFIG_FILE"
    fi
    
    if grep_q "Antigravity Autostart" "$CONFIG_FILE"; then
        echo "Autostart config present in Sway config."
        # Update logic: Remove old block and append new? Or just assume it's okay.
        # For robustness, let's keep it simple: append if missing.
    else
        echo "" >> "$CONFIG_FILE"
        echo "# Antigravity Autostart" >> "$CONFIG_FILE"
        cat "$AUTOSTART_CONF" >> "$CONFIG_FILE"
        echo "Appended autostart to Sway config."
    fi
    
    echo "Reloading Sway..."
    swaymsg reload || echo "Sway reload failed or not running."

# Detect Regolith 3 (i3 mode)
elif [ -d "$HOME/.config/regolith3" ]; then
    echo "Regolith 3 detected."
    # If using i3 with Regolith, we should check if we can modify the partials
    CONFIG_DIR="$HOME/.config/regolith3/i3/config.d"
    mkdir -p "$CONFIG_DIR"
    TARGET_FILE="$CONFIG_DIR/90_autostart"
    
    echo "Installing autostart config to $TARGET_FILE..."
    cp "$AUTOSTART_CONF" "$TARGET_FILE"
    
    # Reload Regolith
    echo "Reloading i3..."
    if command -v i3-msg >/dev/null; then
        i3-msg reload || echo "i3 reload failed or not running."
    fi

# Detect Standard i3
elif [ -d "$HOME/.config/i3" ] || [ -f "$HOME/.i3/config" ]; then
    echo "Standard i3 detected."
    CONFIG_FILE="$HOME/.config/i3/config"
    [ -f "$HOME/.i3/config" ] && CONFIG_FILE="$HOME/.i3/config"
    
    if grep_q "Antigravity Autostart" "$CONFIG_FILE"; then
        echo "Autostart config already present in $CONFIG_FILE"
    else
        echo "Appending autostart config to $CONFIG_FILE..."
        echo "" >> "$CONFIG_FILE"
        echo "# Antigravity Autostart" >> "$CONFIG_FILE"
        cat "$AUTOSTART_CONF" >> "$CONFIG_FILE"
        
        echo "Reloading i3..."
        i3-msg reload || echo "i3 reload failed."
    fi
else
    echo "Could not detect active Sway or i3 config directory."
    echo "Please manually add the contents of $AUTOSTART_CONF to your config."
    exit 1
fi

echo "Done."
