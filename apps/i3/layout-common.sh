#!/usr/bin/env bash
# Shared helpers for per-window keyboard layout (X11 + i3).
# XKB is global; we save/restore the layout when focus changes so each window
# keeps its own remembered layout.

set -euo pipefail

LAYOUT_STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/i3-per-window-layout"
LAYOUT_MAP="$LAYOUT_STATE_DIR/layouts.json"
FOCUS_ID_FILE="$LAYOUT_STATE_DIR/focused_id"
PREV_LAYOUT_FILE="$LAYOUT_STATE_DIR/prev_layout"

mkdir -p "$LAYOUT_STATE_DIR"

ensure_map() {
  if [[ ! -f "$LAYOUT_MAP" ]]; then
    echo '{}' >"$LAYOUT_MAP"
  fi
}

current_layout() {
  if command -v xkb-switch >/dev/null 2>&1; then
    xkb-switch -p 2>/dev/null || true
    return 0
  fi
  setxkbmap -query 2>/dev/null | awk -F': +' '/^layout:/ { print $2; exit }' | tr -d ' '
}

set_layout_to() {
  local target="$1"
  [[ -z "$target" ]] && return 0
  if command -v xkb-switch >/dev/null 2>&1; then
    xkb-switch -s "$target" 2>/dev/null && return 0
  fi
  setxkbmap -layout "$target" 2>/dev/null || true
}

cycle_layout() {
  if command -v xkb-switch >/dev/null 2>&1; then
    xkb-switch -n
    return 0
  fi
  local layouts
  layouts=$(setxkbmap -query 2>/dev/null | awk -F': +' '/^layout:/ { print $2; exit }' | tr ',' ' ')
  if [[ -z "$layouts" ]]; then
    return 1
  fi
  read -r -a arr <<<"$layouts"
  local cur i next n
  cur=$(current_layout)
  n=${#arr[@]}
  [[ "$n" -lt 1 ]] && return 1
  if [[ "$n" -eq 1 ]]; then
    return 0
  fi
  i=0
  for idx in "${!arr[@]}"; do
    if [[ "${arr[$idx]}" == "$cur" ]]; then
      i=$idx
      break
    fi
  done
  next=$(( (i + 1) % n ))
  set_layout_to "${arr[$next]}"
}

map_get() {
  local id="$1"
  ensure_map
  jq -r --arg id "$id" '.[$id] // empty' "$LAYOUT_MAP" 2>/dev/null || true
}

map_set() {
  local id="$1"
  local layout="$2"
  ensure_map
  local tmp
  tmp=$(mktemp)
  jq --arg id "$id" --arg layout "$layout" '.[$id] = $layout' "$LAYOUT_MAP" >"$tmp"
  mv "$tmp" "$LAYOUT_MAP"
}

write_focus_id() {
  echo "$1" >"$FOCUS_ID_FILE"
}

read_focus_id() {
  [[ -f "$FOCUS_ID_FILE" ]] && cat "$FOCUS_ID_FILE" || true
}
