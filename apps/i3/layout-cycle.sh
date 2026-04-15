#!/usr/bin/env bash
# Cycle keyboard layout for the focused i3 window and store it in the per-window map.
# Bind this to Mod4+Mod1+BackSpace (or replace your existing layout toggle).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=layout-common.sh
source "$SCRIPT_DIR/layout-common.sh"

focused_container_id_from_tree() {
  i3-msg -t get_tree 2>/dev/null | jq '.. | objects | select(.focused == true and .window != null) | .id' 2>/dev/null | head -n1
}

if ! command -v i3-msg >/dev/null 2>&1; then
  exit 1
fi

id=$(focused_container_id_from_tree)

cycle_layout
new_layout=$(current_layout)

if [[ -n "$id" && -n "$new_layout" ]]; then
  map_set "$id" "$new_layout"
fi
