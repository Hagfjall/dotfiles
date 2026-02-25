#!/bin/bash
set -e

# Create directories if missing
mkdir -p "$HOME/.local/bin"

# Create wrapper script
cat > "$HOME/.local/bin/wg-quick" << 'EOF'
#!/usr/bin/env bash
# Wrapper for wg-quick to run with sudo automatically
# This allows running 'wg-quick' as a normal user if NOPASSWD sudo is configured.
sudo /usr/bin/wg-quick "$@"
EOF

# Make executable
chmod +x "$HOME/.local/bin/wg-quick"

echo "Successfully installed wg-quick wrapper to $HOME/.local/bin/wg-quick"
echo "You can now run 'wg-quick up wg0' without manually typing sudo."
