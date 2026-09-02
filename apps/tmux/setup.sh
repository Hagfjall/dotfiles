#!/usr/bin/env bash

set -euo pipefail

# Helper functions
have_command() {
  command -v "$1" >/dev/null 2>&1
}

log() {
  printf '[tmux-setup] %s\n' "$*" >&2
}

link_tmux_conf() {
  local src="$1"
  local dst="$2"

  if [ ! -f "$src" ]; then
    log "Source config not found at $src"
    return 1
  fi

  if [ -L "$dst" ]; then
    local current_target
    current_target="$(readlink "$dst")"
    if [ "$current_target" = "$src" ]; then
      log "tmux config already linked ($dst -> $src)"
      return 0
    fi
  elif [ -f "$dst" ]; then
    local backup="${dst}.backup.$(date +%Y-%m-%d_%H-%M-%S)"
    log "Existing config file found at $dst; backing up to $backup"
    mv "$dst" "$backup"
  fi

  mkdir -p "$(dirname "$dst")"
  ln -sfn "$src" "$dst"
  log "Linked $dst -> $src"
}

setup_tmux() {
  local dotfiles_dir="${1:-}"
  local dotfiles_home="${2:-${DOTFILES_HOME:-$HOME}}"

  if [ -z "$dotfiles_dir" ]; then
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    dotfiles_dir="$(cd "$script_dir/../.." && pwd -P)"
  fi

  log "Setting up tmux configuration..."

  local src_conf="$dotfiles_dir/home/.tmux.conf"
  local dst_conf="$dotfiles_home/.tmux.conf"

  link_tmux_conf "$src_conf" "$dst_conf"

  if have_command tmux; then
    # Reload tmux configuration in running server if any exists
    if tmux info >/dev/null 2>&1; then
      tmux source-file "$dst_conf" 2>/dev/null || true
      log "Reloaded active tmux server configuration"
    fi
  else
    log "tmux is not installed. Run apps/tmux/install.sh or install tmux via your package manager."
  fi

  log "tmux setup complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  setup_tmux "$@"
fi
