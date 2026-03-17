#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$HOME/.config/claude-code-telegram/.env"

have_command() {
  command -v "$1" >/dev/null 2>&1
}

echo -e "${YELLOW}=== Claude Code Telegram Bot Installation ===${NC}"
echo ""

# Check for uv
if ! have_command uv; then
    echo -e "${RED}Error: uv is not installed.${NC}"
    echo "Install it with: curl -LsSf https://astral.sh/uv/install.sh | sh"
    exit 1
fi

# Install the bot via uv tool
echo -e "${BLUE}Installing claude-code-telegram via uv...${NC}"
uv tool install git+https://github.com/RichardAtCT/claude-code-telegram
echo -e "${GREEN}✓ Bot installed successfully${NC}"
echo ""

# Set up .env file
mkdir -p "$(dirname "$ENV_FILE")"

if [[ -f "$ENV_FILE" ]]; then
    echo -e "${YELLOW}⚠ .env file already exists at $ENV_FILE — skipping copy.${NC}"
else
    cp "$SCRIPT_DIR/.env" "$ENV_FILE"
    chmod 600 "$ENV_FILE"
    echo -e "${GREEN}✓ .env copied to $ENV_FILE${NC}"
fi

# Install systemd user service
SYSTEMD_DIR="$HOME/.config/systemd/user"
SERVICE_FILE="$SYSTEMD_DIR/claude-code-telegram.service"

mkdir -p "$SYSTEMD_DIR"
cp "$SCRIPT_DIR/claude-code-telegram.service" "$SERVICE_FILE"
echo -e "${GREEN}✓ systemd user service installed at $SERVICE_FILE${NC}"

systemctl --user daemon-reload
systemctl --user enable claude-code-telegram
echo -e "${GREEN}✓ Service enabled (will start on login)${NC}"

sudo loginctl enable-linger "$USER"
echo -e "${GREEN}✓ Linger enabled (service persists after logout)${NC}"
echo ""
echo -e "${GREEN}✓ Installation complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Edit $ENV_FILE and set your real TELEGRAM_BOT_TOKEN and other values"
echo "  2. Start now:    systemctl --user start claude-code-telegram"
echo "  3. Check status: systemctl --user status claude-code-telegram"
echo "  4. View logs:    journalctl --user -u claude-code-telegram -f"
echo ""
