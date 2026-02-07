#!/usr/bin/env bash
#
# WireGuard VPN Setup Script
# Configures passwordless sudo for wg-quick commands
#
# Usage: sudo ./setup-wireguard.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUDOERS_SRC="$SCRIPT_DIR/wireguard-sudoers"
SUDOERS_DST="/etc/sudoers.d/wireguard"

log() {
    printf '[wireguard-setup] %s\n' "$*" >&2
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    log "This script must be run as root (use sudo)"
    exit 1
fi

# Check if source file exists
if [ ! -f "$SUDOERS_SRC" ]; then
    log "Error: Sudoers source file not found at $SUDOERS_SRC"
    exit 1
fi

# Check if wg-quick is installed
if ! command -v wg-quick &>/dev/null; then
    log "Warning: wg-quick not found. Install WireGuard first:"
    log "  sudo apt install wireguard"
fi

# Validate sudoers syntax before installing
if ! visudo -c -f "$SUDOERS_SRC"; then
    log "Error: Invalid sudoers syntax in $SUDOERS_SRC"
    exit 1
fi

# Install the sudoers file
log "Installing sudoers file to $SUDOERS_DST"
cp "$SUDOERS_SRC" "$SUDOERS_DST"
chmod 440 "$SUDOERS_DST"
chown root:root "$SUDOERS_DST"

# Verify installation
if visudo -c; then
    log "Sudoers file installed and validated successfully"
else
    log "Error: Sudoers validation failed after installation"
    rm -f "$SUDOERS_DST"
    exit 1
fi

log ""
log "WireGuard passwordless sudo configured!"
log "You can now use these commands without sudo password:"
log "  sudo wg-quick up wg0"
log "  sudo wg-quick down wg0"
log ""
log "Or with the fish aliases (after sourcing config):"
log "  vpn-up"
log "  vpn-down"
log "  vpn-status"
