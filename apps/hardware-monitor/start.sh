#!/usr/bin/env bash
# Start the hardware monitor dashboard.
# Usage: ./start.sh [port]   (default: 7070)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT="${1:-7070}"

# Check python3
if ! command -v python3 &>/dev/null; then
  echo "Error: python3 is required." >&2
  exit 1
fi

# Warn about optional dependencies
if ! command -v sensors &>/dev/null; then
  echo "Note: 'lm-sensors' not found — CPU temperature will be unavailable."
  echo "      Install with: sudo apt install lm-sensors && sudo sensors-detect"
fi

if ! command -v nvidia-smi &>/dev/null; then
  echo "Note: 'nvidia-smi' not found — GPU stats will be unavailable."
fi

echo "Starting Hardware Monitor on http://localhost:${PORT}"
exec python3 "$SCRIPT_DIR/server.py" "$PORT"
