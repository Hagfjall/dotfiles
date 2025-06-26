#!/usr/bin/env bash
set -e
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

zsh_custom_export='export ZSH_CUSTOM="$DOTFILES/oh-my-zsh-custom/"'
zshrc_file="$HOME/.zshrc"

if ! grep -Fxq "$zsh_custom_export" "$zshrc_file"; then
    sed -i "1i$zsh_custom_export" "$zshrc_file"
fi

dotfiles_export='export DOTFILES="$HOME/.dotfiles'
if ! grep -Fxq "$dotfiles_export" "$zshrc_file"; then
    sed -i "1i$dotfiles_export" "$zshrc_file"
fi


head -n10 $zshrc_file