#!/usr/bin/env bash
# i3status-rust custom block: current XKB layout (keyboard symbol + uppercase code).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=layout-common.sh
source "$SCRIPT_DIR/layout-common.sh"

layout=$(current_layout)
layout=${layout//$'\n'/}

if [[ -z "$layout" ]]; then
  printf '%s ?\n' $'\u2328'
  exit 0
fi

# Comma-separated list: show active layout only (first segment).
layout="${layout%%,*}"

printf '%s %s\n' $'\u2328' "${layout^^}"
