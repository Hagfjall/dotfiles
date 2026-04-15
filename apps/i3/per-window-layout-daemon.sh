#!/usr/bin/env bash
# Subscribes to i3 window events and remembers/restores XKB layout per container.
# Run once from i3: exec --no-startup-id .../per-window-layout-daemon.sh
#
# X11 has one global keyboard layout; this daemon saves the layout when you leave
# a window and reapplies the stored layout when you return.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=layout-common.sh
source "$SCRIPT_DIR/layout-common.sh"

# Allow exec_always in i3: only one subscriber process.
exec 9>"$LAYOUT_STATE_DIR/daemon.lock"
if ! flock -n 9; then
  exit 0
fi

last_id=""

save_layout_for_id() {
  local id="$1"
  local layout="$2"
  [[ -z "$id" ]] && return 0
  [[ -z "$layout" ]] && return 0
  map_set "$id" "$layout"
}

focused_container_id() {
  i3-msg -t get_tree 2>/dev/null | jq '.. | objects | select(.focused == true and .window != null) | .id' 2>/dev/null | head -n1
}

on_focus_change() {
  local new_id saved

  new_id=$(focused_container_id)
  [[ -z "$new_id" ]] && return 0

  if [[ -n "$last_id" && "$last_id" != "$new_id" ]]; then
    save_layout_for_id "$last_id" "$(current_layout)"
  fi

  saved=$(map_get "$new_id")
  if [[ -n "$saved" ]]; then
    set_layout_to "$saved"
  fi

  last_id="$new_id"
  write_focus_id "$new_id"
}

if ! command -v i3-msg >/dev/null 2>&1; then
  exit 0
fi

on_focus_change

i3-msg -t subscribe -m '["window"]' 2>/dev/null | while IFS= read -r line; do
  change=$(echo "$line" | jq -r '.change // empty' 2>/dev/null || true)
  if [[ "$change" == "focus" ]]; then
    on_focus_change
  fi
done
