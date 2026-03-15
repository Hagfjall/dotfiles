#!/usr/bin/env bash
# Install Netdata with Nvidia GPU support and enable autostart via systemd.

set -euo pipefail

# ── Install Netdata ───────────────────────────────────────────────────────────

if command -v netdata &>/dev/null; then
  echo "Netdata is already installed, skipping install."
else
  echo "Installing Netdata..."
  curl -fsSL https://get.netdata.cloud/kickstart.sh | bash -s -- --non-interactive --no-updates
fi

# ── Enable Nvidia GPU collector ───────────────────────────────────────────────

if command -v nvidia-smi &>/dev/null; then
  echo "Nvidia GPU detected — enabling nvidia_smi collector..."

  CONF_DIR="/etc/netdata/go.d"
  sudo mkdir -p "$CONF_DIR"

  # Only write config if it doesn't already exist
  if [[ ! -f "$CONF_DIR/nvidia_smi.conf" ]]; then
    sudo tee "$CONF_DIR/nvidia_smi.conf" > /dev/null <<'EOF'
jobs:
  - name: local
    binary_path: /usr/bin/nvidia-smi
    timeout: 10
EOF
  fi
else
  echo "Note: nvidia-smi not found — GPU collector will not be enabled."
fi

# ── Autostart via systemd ─────────────────────────────────────────────────────

echo "Enabling Netdata to autostart on boot..."
sudo systemctl enable netdata
sudo systemctl restart netdata

# ── Done ──────────────────────────────────────────────────────────────────────

echo ""
echo "Netdata is running at http://localhost:19999"
echo "It will start automatically on boot."
