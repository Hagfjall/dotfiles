#!/usr/bin/env bash

set -euo pipefail

# Helper functions
have_command() {
  command -v "$1" >/dev/null 2>&1
}

log() {
  printf '[less-setup] %s\n' "$*" >&2
}

link_file() {
  local src="$1"
  local dst="$2"

  if [ ! -f "$src" ]; then
    log "Source file not found at $src"
    return 1
  fi

  if [ -L "$dst" ]; then
    local current_target
    current_target="$(readlink "$dst")"
    if [ "$current_target" = "$src" ]; then
      return 0
    fi
  elif [ -f "$dst" ]; then
    local backup="${dst}.backup.$(date +%Y-%m-%d_%H-%M-%S)"
    log "Existing file found at $dst; backing up to $backup"
    mv "$dst" "$backup"
  fi

  mkdir -p "$(dirname "$dst")"
  ln -sfn "$src" "$dst"
  log "Linked $dst -> $src"
}

setup_bat_alias() {
  local dotfiles_home="$1"
  local bat_dst="$dotfiles_home/.local/bin/bat"

  # On Debian/Ubuntu, bat is installed as /usr/bin/batcat
  if [ -x /usr/bin/batcat ] && [ ! -e "$bat_dst" ]; then
    mkdir -p "$dotfiles_home/.local/bin"
    ln -sfn /usr/bin/batcat "$bat_dst"
    log "Linked $bat_dst -> /usr/bin/batcat"
  fi
}

setup_shell_configs() {
  local dotfiles_home="$1"

  # 1. Update ~/.bashrc if needed
  local bashrc="$dotfiles_home/.bashrc"
  if [ -f "$bashrc" ]; then
    if ! grep -q 'export LESS=' "$bashrc" && ! grep -q 'LESS=' "$bashrc"; then
      log "Adding LESS=\"-R\" to $bashrc"
      printf '\n# Enable raw ANSI colors in less\nexport LESS="-R"\nexport BAT_THEME="GitHub"\nexport LESSFILTER_STYLE="friendly"\n' >> "$bashrc"
    fi
  fi

  # 2. Update ~/.profile if needed
  local profile="$dotfiles_home/.profile"
  if [ -f "$profile" ]; then
    if ! grep -q 'export LESS=' "$profile" && ! grep -q 'LESS=' "$profile"; then
      log "Adding LESS=\"-R\" to $profile"
      printf '\n# Enable raw ANSI colors in less\nexport LESS="-R"\nexport BAT_THEME="GitHub"\nexport LESSFILTER_STYLE="friendly"\n' >> "$profile"
    fi
  fi

  # 3. Update ~/.zshrc if needed
  local zshrc="$dotfiles_home/.zshrc"
  if [ -f "$zshrc" ]; then
    if grep -q 'export LESSOPEN="| /usr/bin/highlight' "$zshrc"; then
      log "Cleaning up legacy highlight LESSOPEN in $zshrc"
      sed -i 's|export LESSOPEN="| /usr/bin/highlight %s --out-format xterm256 --force"|# LESSOPEN configured via lesspipe / lessfilter\n[ -x /usr/bin/lesspipe ] \&\& eval "$(SHELL=/bin/sh lesspipe)"|' "$zshrc"
    fi
    if ! grep -q 'export LESS=' "$zshrc" && ! grep -q 'LESS=' "$zshrc"; then
      log "Adding LESS=\"-R\" to $zshrc"
      printf '\n# Enable raw ANSI colors in less\nexport LESS="-R"\nexport BAT_THEME="GitHub"\nexport LESSFILTER_STYLE="friendly"\n' >> "$zshrc"
    fi
  fi
}

setup_less() {
  local dotfiles_dir="${1:-}"
  local dotfiles_home="${2:-${DOTFILES_HOME:-$HOME}}"

  if [ -z "$dotfiles_dir" ]; then
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    dotfiles_dir="$(cd "$script_dir/../.." && pwd -P)"
  fi

  log "Setting up less syntax highlighting configuration..."

  local src_filter="$dotfiles_dir/home/.config/lessfilter"
  local src_fish="$dotfiles_dir/home/.config/fish/conf.d/less.fish"

  chmod +x "$src_filter"

  # Link lessfilter to standard XDG config, local bin, and fallback ~/.lessfilter
  link_file "$src_filter" "$dotfiles_home/.config/lessfilter"
  link_file "$src_filter" "$dotfiles_home/.local/bin/lessfilter"
  link_file "$src_filter" "$dotfiles_home/.lessfilter"

  # Link fish config
  link_file "$src_fish" "$dotfiles_home/.config/fish/conf.d/less.fish"

  # Setup bat symlink if batcat is present
  setup_bat_alias "$dotfiles_home"

  # Update bash/zsh/profile
  setup_shell_configs "$dotfiles_home"

  # Verify syntax highlighting capability
  if have_command bat || have_command batcat; then
    log "Rust syntax highlighter (bat) detected and configured."
  elif have_command pygmentize; then
    log "Python syntax highlighter (pygmentize) detected and configured (light theme: friendly)."
  elif have_command highlight; then
    log "Highlight tool detected and configured (light theme: github)."
  else
    log "Warning: No syntax highlighter found. Please install bat, python3-pygments, or highlight."
  fi

  log "less syntax highlighting setup complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  setup_less "$@"
fi
