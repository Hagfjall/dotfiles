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

if [ -d "/opt/dev/dotfiles" ]; then
    mkdir -p "$HOME/.dotfiles/"
    cp -r "/opt/dev/dotfiles/." "$HOME/.dotfiles/"
else
    git clone --depth=1 https://github.com/hagfjall/dotfiles.git $HOME/.dotfiles
fi
cd $HOME/.dotfiles
script/install
script/bootstrap

# zsh
# test
ls -ahl $HOME
which zsh
zsh -c ". ~/.zshrc; echo -n DOTFILES: $DOTFILES; echo -n ZSH: $ZSH; echo -n plugins: $plugins; ps"
zsh -ic "echo DOTFILES: $DOTFILES; echo ZSH: $ZSH"
zsh -ic "echo plugins: $plugins"
zsh -ic "st"
zsh -ic "agli"