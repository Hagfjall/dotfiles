#!/usr/bin/env fish

function log
  printf '[dotfiles] %s\n' $argv >&2
end

if not type -q curl
  log "curl is required to install fisher"
  exit 1
end

if not type -q fisher
  log "Installing fisher"
  curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
  fisher install jorgebucaran/fisher
else
  log "fisher already installed"
end

set plugins jethrokuan/z IlanCosman/tide
for plugin in $plugins
  log "Installing fisher plugin: $plugin"
  fisher install $plugin
  or begin
    log "Warning: Failed to install $plugin. Run 'fisher install $plugin' manually."
  end
end

