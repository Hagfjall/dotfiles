if status is-interactive
    set -g fish_greeting ""
end

if test -d "$HOME/.local/bin"
    fish_add_path "$HOME/.local/bin"
end




# Added by Antigravity CLI installer
set -gx PATH "/home/user/.local/bin" $PATH
