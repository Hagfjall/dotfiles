#!/usr/bin/env bash
set -e
apt_update_ran=false
install_if_missing() {
    local cmd="$1"
    local pkg="${2:-$1}"
    if ! type -p "$cmd" >/dev/null; then
        if ! $apt_update_ran; then
            apt update
            apt_update_ran=true
        fi
        apt install -y "$pkg"
    fi
}

install_if_missing curl
install_if_missing git
install_if_missing zsh
git clone --depth=1 https://github.com/hagfjall/dotfiles.git $HOME/.dotfiles
cd $HOME/.dotfiles
script/bootstrap