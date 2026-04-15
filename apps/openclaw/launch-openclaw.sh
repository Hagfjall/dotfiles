#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLICY_FILE="$SCRIPT_DIR/openclaw-policy.yaml"
CHROME_DEBUG_PORT=9222
OPENCLAW_PORT=18789
SANDBOX_NAME="openclaw"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log() { echo "[launch-openclaw] $*"; }
die() { echo "[launch-openclaw] ERROR: $*" >&2; exit 1; }

command -v openshell &>/dev/null || die "openshell not found. Install it with: curl -LsSf https://raw.githubusercontent.com/NVIDIA/OpenShell/main/install.sh | sh"

# ---------------------------------------------------------------------------
# 1. Start Chrome with remote debugging enabled
# ---------------------------------------------------------------------------
start_chrome() {
  # Detect available Chrome/Chromium binary
  local chrome_bin=""
  for bin in google-chrome google-chrome-stable chromium chromium-browser; do
    if command -v "$bin" &>/dev/null; then
      chrome_bin="$bin"
      break
    fi
  done

  if [[ -z "$chrome_bin" ]]; then
    die "No Chrome/Chromium binary found. Install google-chrome or chromium."
  fi

  # Check if Chrome is already listening on the debug port
  if ss -tlnp 2>/dev/null | grep -q ":${CHROME_DEBUG_PORT}"; then
    log "Chrome DevTools Protocol already listening on port $CHROME_DEBUG_PORT — skipping Chrome launch."
    return
  fi

  log "Starting $chrome_bin with remote debugging on port $CHROME_DEBUG_PORT ..."
  "$chrome_bin" \
    --remote-debugging-port="$CHROME_DEBUG_PORT" \
    --remote-debugging-address=0.0.0.0 \
    --no-first-run \
    --no-default-browser-check \
    --disable-background-networking \
    --disable-extensions \
    --disable-sync \
    --disable-translate \
    --safebrowsing-disable-auto-update \
    --user-data-dir="/tmp/chrome-openclaw-profile" \
    about:blank &>/tmp/chrome-openclaw.log &

  # Wait for Chrome DevTools to become available
  local retries=20
  while ! ss -tlnp 2>/dev/null | grep -q ":${CHROME_DEBUG_PORT}" && (( retries-- > 0 )); do
    sleep 0.5
  done

  if ! ss -tlnp 2>/dev/null | grep -q ":${CHROME_DEBUG_PORT}"; then
    die "Chrome did not open the debug port in time. Check /tmp/chrome-openclaw.log"
  fi

  log "Chrome CDP ready at http://localhost:$CHROME_DEBUG_PORT"
}

# ---------------------------------------------------------------------------
# 2. Ensure an OpenShell gateway is running and selected
# ---------------------------------------------------------------------------
ensure_gateway() {
  local gateway_name="openshell"

  # Check if a gateway is already active by attempting to get info
  if openshell gateway info --gateway "$gateway_name" &>/dev/null; then
    log "Gateway '$gateway_name' already exists — selecting it ..."
    openshell gateway select "$gateway_name"
  else
    log "Starting OpenShell gateway '$gateway_name' ..."
    openshell gateway start --name "$gateway_name" --recreate
  fi

  log "Gateway ready."
}

# ---------------------------------------------------------------------------
# 3. Register Anthropic API key as an OpenShell provider
# ---------------------------------------------------------------------------
register_anthropic_provider() {
  # Allow the key to be passed as an argument or picked up from the environment
  if [[ -n "${1:-}" ]]; then
    export ANTHROPIC_API_KEY="$1"
  fi

  if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
    die "ANTHROPIC_API_KEY is not set. Export it before running this script, or pass it as the first argument:
  ANTHROPIC_API_KEY=sk-ant-... ./launch-openclaw.sh
  ./launch-openclaw.sh sk-ant-..."
  fi

  log "Registering Anthropic provider with OpenShell ..."
  openshell provider create --name anthropic --type anthropic --from-existing 2>&1 | grep -v "AlreadyExists\|provider already exists" || true
  log "Anthropic provider registered (or already existed)."
}

# ---------------------------------------------------------------------------
# 3. Launch OpenClaw sandbox
# ---------------------------------------------------------------------------
launch_openclaw() {
  # Tear down any existing sandbox with the same name
  if openshell sandbox list 2>/dev/null | grep -q "^$SANDBOX_NAME"; then
    log "Removing existing sandbox '$SANDBOX_NAME' ..."
    openshell sandbox delete "$SANDBOX_NAME" --yes 2>/dev/null || true
  fi

  log "Creating OpenClaw sandbox '$SANDBOX_NAME' ..."
  openshell sandbox create \
    --name "$SANDBOX_NAME" \
    --from openclaw \
    --policy "$POLICY_FILE" \
    --forward "$OPENCLAW_PORT" \
    -- openclaw-start

  log ""
  log "OpenClaw is running."
  log "  Web UI  : http://127.0.0.1:$OPENCLAW_PORT/"
  log "  Chrome  : ws://localhost:$CHROME_DEBUG_PORT  (CDP)"
  log ""
  log "Connect to the sandbox:  openshell sandbox connect $SANDBOX_NAME"
  log "Stop the sandbox:        openshell sandbox delete $SANDBOX_NAME --yes"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
start_chrome
ensure_gateway
register_anthropic_provider "${1:-}"
launch_openclaw
