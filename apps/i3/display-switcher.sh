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

log() {
  printf '[display-switcher] %s\n' "$*" >&2
}

# Detect session type
detect_session() {
  if [ "${XDG_SESSION_TYPE:-}" = "wayland" ]; then
    echo "wayland"
  else
    echo "x11"
  fi
}

# ============================================================================
# WAYLAND/SWAY FUNCTIONS
# ============================================================================

# Get outputs from Sway
get_sway_outputs() {
  if ! have_command swaymsg; then
    echo -e "${RED}Error: swaymsg not found${NC}"
    exit 1
  fi

  swaymsg -t get_outputs 2>/dev/null | jq -r '.[] | .name' || true
}

# Detect Sway displays
detect_displays_sway() {
  local all_outputs
  all_outputs=$(get_sway_outputs)

  if [ -z "$all_outputs" ]; then
    echo "ERROR: No connected displays detected"
    return 1
  fi

  local laptop=""
  local externals=()

  # Identify laptop display (typically eDP-1, eDP-2, OLED-1, etc.)
  while IFS= read -r output; do
    if [[ "$output" =~ ^(eDP|OLED|LVDS) ]]; then
      laptop="$output"
    else
      externals+=("$output")
    fi
  done <<< "$all_outputs"

  echo "LAPTOP=$laptop"
  for ext in "${externals[@]}"; do
    echo "EXTERNAL=$ext"
  done
}

# Apply laptop only mode (Sway)
mode_laptop_only_sway() {
  local laptop="$1"
  shift
  local externals=("$@")

  log "Applying mode: Laptop only"

  swaymsg "output $laptop enable"

  for ext in "${externals[@]}"; do
    swaymsg "output $ext disable"
  done

  have_command notify-send && notify-send "Display Mode" "Laptop screen only" -i video-display || true
}

# Apply external monitor only mode (Sway)
mode_external_only_sway() {
  local laptop="$1"
  local external="$2"

  log "Applying mode: External only"

  swaymsg "output $laptop disable"
  swaymsg "output $external enable"

  have_command notify-send && notify-send "Display Mode" "External monitor only" -i video-display || true
}

# Apply extended desktop mode (Sway)
mode_extended_sway() {
  local laptop="$1"
  local external="$2"

  log "Applying mode: Extended desktop"

  swaymsg "output $laptop enable"
  swaymsg "output $external enable"

  have_command notify-send && notify-send "Display Mode" "Extended desktop (external right of laptop)" -i video-display || true
}

# ============================================================================
# X11 FUNCTIONS
# ============================================================================

check_dependencies_x11() {
  local missing=()

  for cmd in xrandr rofi; do
    if ! have_command "$cmd"; then
      missing+=("$cmd")
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    echo -e "${RED}Error: Missing required commands: ${missing[*]}${NC}"
    echo "Please run: sudo $(dirname "$(readlink -f "$0")")/install.sh"
    exit 1
  fi
}

# Detect available displays (X11)
detect_displays_x11() {
  local all_displays
  all_displays=$(xrandr --query | grep " connected" | awk '{print $1}')

  if [ -z "$all_displays" ]; then
    echo "ERROR: No connected displays detected"
    return 1
  fi

  local laptop=""
  local externals=()

  while IFS= read -r display; do
    if [[ "$display" =~ ^(eDP|LVDS) ]]; then
      laptop="$display"
    else
      externals+=("$display")
    fi
  done <<< "$all_displays"

  echo "LAPTOP=$laptop"
  for ext in "${externals[@]}"; do
    echo "EXTERNAL=$ext"
  done
}

# Apply laptop only mode (X11)
mode_laptop_only_x11() {
  local laptop="$1"
  shift
  local externals=("$@")

  log "Applying mode: Laptop only"

  xrandr --output "$laptop" --auto --primary

  for ext in "${externals[@]}"; do
    xrandr --output "$ext" --off
  done

  have_command notify-send && notify-send "Display Mode" "Laptop screen only" -i video-display || true
}

# Apply external monitor only mode (X11)
mode_external_only_x11() {
  local laptop="$1"
  local external="$2"

  log "Applying mode: External only"

  xrandr --output "$laptop" --off
  xrandr --output "$external" --auto --primary

  have_command notify-send && notify-send "Display Mode" "External monitor only" -i video-display || true
}

# Apply extended desktop mode (X11)
mode_extended_x11() {
  local laptop="$1"
  local external="$2"

  log "Applying mode: Extended desktop"

  xrandr --output "$laptop" --auto --primary
  xrandr --output "$external" --auto --right-of "$laptop"

  have_command notify-send && notify-send "Display Mode" "Extended desktop (external right of laptop)" -i video-display || true
}

# ============================================================================
# COMMON FUNCTIONS
# ============================================================================

# Show rofi menu and get user selection
show_menu() {
  local has_external="$1"

  if [ "$has_external" = "true" ]; then
    echo -e "Laptop only\nExternal only\nExtended desktop" | rofi -dmenu -i -p "Display Mode (Super+P)"
  else
    echo -e "Laptop only" | rofi -dmenu -i -p "Display Mode (Super+P)"
  fi
}

# Check dependencies for rofi
check_rofi() {
  if ! have_command rofi; then
    echo -e "${RED}Error: rofi not found${NC}"
    echo "Please run: sudo $(dirname "$(readlink -f "$0")")/../install.sh"
    exit 1
  fi
}

# ============================================================================
# MAIN LOGIC
# ============================================================================

main() {
  SESSION=$(detect_session)
  check_rofi

  if [ "$SESSION" = "wayland" ]; then
    # Wayland/Sway path
    log "Using Wayland/Sway display management"

    # Detect displays
    local display_info
    display_info=$(detect_displays_sway) || {
      echo -e "${RED}Error: Failed to detect displays${NC}"
      exit 1
    }

    # Parse display info
    local laptop=""
    local externals=()

    while IFS='=' read -r key value; do
      if [ "$key" = "LAPTOP" ]; then
        laptop="$value"
      elif [ "$key" = "EXTERNAL" ]; then
        externals+=("$value")
      fi
    done <<< "$display_info"

    if [ -z "$laptop" ]; then
      echo -e "${RED}Error: Could not detect laptop display${NC}"
      exit 1
    fi

    log "Detected laptop: $laptop"

    local has_external="false"
    if [ ${#externals[@]} -gt 0 ]; then
      has_external="true"
      log "Detected external display(s): ${externals[*]}"
    fi

    # Show menu and get selection
    local choice
    choice=$(show_menu "$has_external")

    if [ -z "$choice" ]; then
      log "User cancelled menu"
      exit 0
    fi

    # Apply selected mode
    case "$choice" in
      "Laptop only")
        mode_laptop_only_sway "$laptop" "${externals[@]}"
        ;;
      "External only")
        if [ "$has_external" = "true" ] && [ ${#externals[@]} -gt 0 ]; then
          mode_external_only_sway "$laptop" "${externals[0]}"
        else
          echo -e "${RED}Error: No external monitor detected${NC}"
          exit 1
        fi
        ;;
      "Extended desktop")
        if [ "$has_external" = "true" ] && [ ${#externals[@]} -gt 0 ]; then
          mode_extended_sway "$laptop" "${externals[0]}"
        else
          echo -e "${RED}Error: No external monitor detected${NC}"
          exit 1
        fi
        ;;
      *)
        log "Unknown selection: $choice"
        exit 1
        ;;
    esac

  else
    # X11 path
    log "Using X11/xrandr display management"
    check_dependencies_x11

    # Detect displays
    local display_info
    display_info=$(detect_displays_x11) || {
      echo -e "${RED}Error: Failed to detect displays${NC}"
      exit 1
    }

    # Parse display info
    local laptop=""
    local externals=()

    while IFS='=' read -r key value; do
      if [ "$key" = "LAPTOP" ]; then
        laptop="$value"
      elif [ "$key" = "EXTERNAL" ]; then
        externals+=("$value")
      fi
    done <<< "$display_info"

    if [ -z "$laptop" ]; then
      echo -e "${RED}Error: Could not detect laptop display${NC}"
      exit 1
    fi

    log "Detected laptop: $laptop"

    local has_external="false"
    if [ ${#externals[@]} -gt 0 ]; then
      has_external="true"
      log "Detected external display(s): ${externals[*]}"
    fi

    # Show menu and get selection
    local choice
    choice=$(show_menu "$has_external")

    if [ -z "$choice" ]; then
      log "User cancelled menu"
      exit 0
    fi

    # Apply selected mode
    case "$choice" in
      "Laptop only")
        mode_laptop_only_x11 "$laptop" "${externals[@]}"
        ;;
      "External only")
        if [ "$has_external" = "true" ] && [ ${#externals[@]} -gt 0 ]; then
          mode_external_only_x11 "$laptop" "${externals[0]}"
        else
          echo -e "${RED}Error: No external monitor detected${NC}"
          exit 1
        fi
        ;;
      "Extended desktop")
        if [ "$has_external" = "true" ] && [ ${#externals[@]} -gt 0 ]; then
          mode_extended_x11 "$laptop" "${externals[0]}"
        else
          echo -e "${RED}Error: No external monitor detected${NC}"
          exit 1
        fi
        ;;
      *)
        log "Unknown selection: $choice"
        exit 1
        ;;
    esac
  fi
}

main "$@"
