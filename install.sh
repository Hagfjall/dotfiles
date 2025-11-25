#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_HOME="${DOTFILES_HOME:-$HOME}"

log() {
  printf '[dotfiles] %s\n' "$*" >&2
}

install_packages() {
  local packages=(git sudo ca-certificates curl fish)

  if command -v apt-get >/dev/null 2>&1; then
    local sudo_cmd=""
    if [ "$(id -u)" -ne 0 ]; then
      if command -v sudo >/dev/null 2>&1; then
        sudo_cmd="sudo"
      else
        log "apt-get detected but sudo missing; skipping automatic package install"
        return
      fi
    fi
    log "Installing required packages via apt-get: ${packages[*]}"
    $sudo_cmd apt-get update
    $sudo_cmd apt-get install -y "${packages[@]}"
    return
  fi

  if command -v fish >/dev/null 2>&1; then
    log "fish already installed"
    return
  fi

  log "fish is not installed and automatic install is not supported on this platform"
  log "Please install fish manually and re-run this script."
}

install_fisher() {
  if ! command -v fish >/dev/null 2>&1; then
    log "fish is not installed. Skipping fisher installation."
    return
  fi

  local fish_installer="$DOTFILES_DIR/scripts/install_fisher.fish"
  if [ ! -f "$fish_installer" ]; then
    log "fish installer script missing at $fish_installer"
    return 1
  fi

  log "Running fish installer script"
  fish "$fish_installer"
}

link_path() {
  local src="$1"
  local dst="$2"

  if [ -d "$src" ]; then
    mkdir -p "$dst"
    return
  fi

  mkdir -p "$(dirname "$dst")"
  ln -sfn "$src" "$dst"
  log "Linked $dst -> $src"
}

link_dotfiles() {
  find "$DOTFILES_DIR/home" -mindepth 1 -print0 | while IFS= read -r -d '' path; do
    rel="${path#$DOTFILES_DIR/home/}"
    target="$DOTFILES_HOME/$rel"
    link_path "$path" "$target"
  done
}

main() {
  install_packages
  link_dotfiles
  install_fisher
  log "Installation complete. Open a new fish shell to load the configuration."
}

main "$@"


