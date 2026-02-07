# Aliases synced from host shell configuration
alias ga 'git add'
alias gc 'git commit'
alias gcm 'gco main'
alias gco 'git checkout'
alias gd 'git diff'
alias gdc 'git diff --cached'
alias gf 'git fetch'
alias gl 'git pull'
alias gp 'git push'
alias l 'ls -ahl'
alias ll 'l'
alias st 'git status'

# VPN aliases (requires setup-wireguard.sh to be run first)
alias vpn-up 'sudo wg-quick up wg0'
alias vpn-down 'sudo wg-quick down wg0'
alias vpn-status 'sudo wg show wg0 2>/dev/null && echo "VPN: Connected" || echo "VPN: Disconnected"'
