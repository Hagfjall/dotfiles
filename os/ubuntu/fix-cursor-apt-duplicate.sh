#!/bin/bash
# Removes duplicate Cursor APT source: cursor-apparmor.sources mirrors cursor.sources
# and triggers "configured multiple times" warnings from apt.

set -euo pipefail

DUP="/etc/apt/sources.list.d/cursor-apparmor.sources"
MAIN="/etc/apt/sources.list.d/cursor.sources"

if [[ $EUID -ne 0 ]]; then
    echo "Error: run as root: sudo $0"
    exit 1
fi

if [[ ! -f "$DUP" ]]; then
    echo "No $DUP — nothing to do."
    exit 0
fi

if [[ ! -f "$MAIN" ]]; then
    echo "Unexpected: $DUP exists but $MAIN is missing. Fix manually."
    exit 1
fi

if ! cmp -s "$DUP" "$MAIN"; then
    echo "Files differ; not removing automatically."
    echo "Compare: diff -u $MAIN $DUP"
    exit 1
fi

rm -v "$DUP"
echo "Removed duplicate Cursor APT entry (kept $MAIN)."
apt update
