#!/usr/bin/env bash

# CopyQ Status Bar Module for Regolith i3status-rs
# This script displays CopyQ status in the Regolith status bar
# It shows the number of items in clipboard history and indicates if CopyQ is running

# Get the number of items in CopyQ history
get_clipboard_count() {
    if ! command -v copyq >/dev/null 2>&1; then
        echo "0"
        return
    fi

    # Try to get the count from CopyQ
    # If CopyQ is not running, this will fail gracefully
    count=$(copyq count 2>/dev/null || echo "0")
    echo "$count"
}

# Check if CopyQ is running
is_copyq_running() {
    pgrep -q copyq
}

# Format the output for i3status-rs
display_status() {
    local count
    count=$(get_clipboard_count)

    if is_copyq_running; then
        # Show clipboard count in green
        echo "📋 $count"
    else
        # Show disconnected state
        echo "📋 ✕"
    fi
}

# Main loop for i3status-rs
main() {
    while true; do
        display_status
        sleep 2
    done
}

main
