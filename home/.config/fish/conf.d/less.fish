# Enable raw control characters for ANSI color escape sequences in less
set -gx LESS "-R"

# Light terminal color themes
set -q BAT_THEME; or set -gx BAT_THEME "GitHub"
set -q LESSFILTER_STYLE; or set -gx LESSFILTER_STYLE "friendly"

# Set input preprocessor for less
if test -x /usr/bin/lesspipe
    set -gx LESSOPEN "| /usr/bin/lesspipe %s"
    set -gx LESSCLOSE "/usr/bin/lesspipe %s %s"
else if test -x "$HOME/.config/lessfilter"
    set -gx LESSOPEN "| $HOME/.config/lessfilter %s"
else if command -v lessfilter >/dev/null 2>&1
    set -gx LESSOPEN "| lessfilter %s"
end
