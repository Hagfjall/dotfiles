#!/usr/bin/env bash
#
# VPN Status Script for i3status-rust
# Checks if WireGuard VPN (wg0) is connected and outputs status
#
# Returns:
#   - Icon and "VPN" text when connected
#   - Empty string when not connected (block won't show)

# Check if wg0 interface exists and is up
if ip link show wg0 &>/dev/null; then
    # wg0 interface exists, VPN is connected
    echo "🌐🔗"
fi

# If wg0 doesn't exist, output nothing (block will be hidden)
