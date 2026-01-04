#!/usr/bin/env bash

set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/hagfjall/dotfiles.git}"
DOTFILES_CLONE_DIR="${DOTFILES_CLONE_DIR:-$HOME/.local/share/dotfiles}"
DOTFILES_DIR=""
DOTFILES_HOME="${DOTFILES_HOME:-$HOME}"

log() {
  printf '[dotfiles] %s\n' "$*" >&2
}

have_command() {
  command -v "$1" >/dev/null 2>&1
}

have_package() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}

script_dir_from_source() {
  local source_path="${BASH_SOURCE[0]:-}"
  local candidate_dir

  if [ -z "$source_path" ]; then
    return 1
  fi

  candidate_dir="$(dirname "$source_path" 2>/dev/null || true)"
  if [ -z "$candidate_dir" ] || ! [ -d "$candidate_dir" ]; then
    return 1
  fi

  if candidate_dir="$(cd "$candidate_dir" >/dev/null 2>&1 && pwd -P)"; then
    if [ -d "$candidate_dir/home" ] || [ -d "$candidate_dir/.git" ]; then
      printf '%s\n' "$candidate_dir"
      return 0
    fi
  fi

  return 1
}

resolve_dotfiles_dir() {
  if [ -n "${DOTFILES_DIR:-}" ] && [ -d "$DOTFILES_DIR" ]; then
    printf '%s\n' "$DOTFILES_DIR"
    return 0
  fi

  if script_dir="$(script_dir_from_source)"; then
    printf '%s\n' "$script_dir"
    return 0
  fi

  printf '%s\n' "$DOTFILES_CLONE_DIR"
}

ensure_repo_present() {
  local dir="$1"

  if [ -d "$dir/.git" ]; then
    log "Updating existing repository in $dir"
    git -C "$dir" pull --ff-only
    return
  fi

  if [ -d "$dir/home" ] || [ -f "$dir/install.sh" ]; then
    log "Using existing dotfiles directory in $dir"
    return
  fi

  if [ -d "$dir" ] && [ "$(ls -A "$dir" 2>/dev/null)" ]; then
    log "Target directory $dir exists and is not empty; refusing to overwrite"
    exit 1
  fi

  if [ -d "$dir" ]; then
    rmdir "$dir"
  fi
  mkdir -p "$(dirname "$dir")"
  log "Cloning dotfiles repository into $dir"
  git clone "$REPO_URL" "$dir"
}

install_packages() {
  local packages=(git sudo ca-certificates curl fish)

  if have_command apt-get; then
    local sudo_cmd=""
    if [ "$(id -u)" -ne 0 ]; then
      if have_command sudo; then
        sudo_cmd="sudo"
      else
        log "apt-get detected but sudo missing; skipping automatic package install"
        return
      fi
    fi

    # Filter out packages that are already installed
    local packages_to_install=()
    for pkg in "${packages[@]}"; do
      case "$pkg" in
        ca-certificates)
          # Package without a command - check using dpkg
          if ! have_package "$pkg"; then
            packages_to_install+=("$pkg")
          fi
          ;;
        *)
          # Package with a command - check using command -v
          if ! have_command "$pkg"; then
            packages_to_install+=("$pkg")
          fi
          ;;
      esac
    done

    if [ ${#packages_to_install[@]} -eq 0 ]; then
      log "All required packages are already installed"
      return
    fi

    log "Installing required packages via apt-get: ${packages_to_install[*]}"
    $sudo_cmd apt-get update
    $sudo_cmd apt-get install -y "${packages_to_install[@]}"
    return
  fi

  if have_command fish; then
    log "fish already installed"
    return
  fi

  log "fish is not installed and automatic install is not supported on this platform"
  log "Please install fish manually and re-run this script."
}

install_fisher() {
  if ! have_command fish; then
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

set_default_shell_to_fish() {
  if ! have_command fish; then
    log "fish not installed; cannot set it as default shell."
    return
  fi

  local target_user current_shell fish_path shells_file sudo_cmd=""
  fish_path="$(command -v fish)"
  shells_file="/etc/shells"

  if [ -n "${SUDO_USER:-}" ]; then
    target_user="$SUDO_USER"
  elif [ -n "${USER:-}" ]; then
    target_user="$USER"
  else
    target_user="$(id -un 2>/dev/null || true)"
  fi

  if [ -z "$target_user" ]; then
    log "Unable to determine target user for chsh."
    return
  fi

  if have_command getent; then
    current_shell="$(getent passwd "$target_user" | cut -d: -f7)"
  else
    current_shell="${SHELL:-}"
  fi

  if [ "$current_shell" = "$fish_path" ]; then
    log "fish already set as default shell for $target_user"
    return
  fi

  if [ ! -f "$shells_file" ] || ! grep -Fxq "$fish_path" "$shells_file"; then
    if [ "$(id -u)" -ne 0 ]; then
      if have_command sudo; then
        sudo_cmd="sudo"
      else
        log "Need sudo to add fish to $shells_file; skipping default shell change."
        return
      fi
    fi
    log "Adding $fish_path to $shells_file"
    $sudo_cmd sh -c "echo '$fish_path' >> '$shells_file'"
  fi

  if ! have_command chsh; then
    log "chsh command not available; cannot change default shell."
    return
  fi

  if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
    log "Setting default shell for $target_user to $fish_path"
    chsh -s "$fish_path" "$target_user"
  else
    log "Setting default shell for $target_user to $fish_path"
    chsh -s "$fish_path"
  fi
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

setup_regolith() {
  # Check if Regolith is installed
  if ! have_package "regolith-desktop" && [ -z "${REGOLITH_VERSION:-}" ]; then
    return
  fi

  log "Regolith detected, setting up power menu desktop entries"

  # Update desktop database after symlinks are created
  if have_command update-desktop-database; then
    update-desktop-database "$DOTFILES_HOME/.local/share/applications" 2>/dev/null || true
    log "Updated desktop database for power menu entries"
  fi
}

main() {
  install_packages

  if ! have_command git; then
    log "git is required to fetch the repository but was not found."
    exit 1
  fi

  local resolved_dir
  resolved_dir="$(resolve_dotfiles_dir)"
  ensure_repo_present "$resolved_dir"
  DOTFILES_DIR="$resolved_dir"

  link_dotfiles
  setup_regolith
  install_fisher
  set_default_shell_to_fish
  log "Installation complete. Open a new fish shell to load the configuration."
}

main "$@"


