#!/usr/bin/env bash
set -e
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

zshrc_file="$HOME/.zshrc"

zsh_custom_export='export ZSH_CUSTOM="$DOTFILES/oh-my-zsh-custom/"'
# prepend to the file
if ! grep -Fxq "$zsh_custom_export" "$zshrc_file"; then
    sed -i "1i$zsh_custom_export" "$zshrc_file"
fi

dotfiles_export='export DOTFILES="$HOME/.dotfiles"'
# prepend to the file
if ! grep -Fxq "$dotfiles_export" "$zshrc_file"; then
    sed -i "1i$dotfiles_export" "$zshrc_file"
fi

plugins_config="plugins=(git git-extras ubuntu)"
sed -i "/^plugins=/c\\$plugins_config" "$HOME/.zshrc"
