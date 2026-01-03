#!/usr/bin/env fish

function log
  printf '[dotfiles] %s\n' $argv >&2
end

function get_fisher_timestamp_file
  set -l state_dir (set -q XDG_STATE_HOME; and echo $XDG_STATE_HOME; or echo $HOME/.local/state)
  echo $state_dir/fisher/last_install
end

function should_update_fisher
  set -l timestamp_file (get_fisher_timestamp_file)

  # If timestamp file doesn't exist, update needed
  if not test -f $timestamp_file
    return 0
  end

  # Read and validate timestamp
  set -l last_install (cat $timestamp_file 2>/dev/null)
  if test -z "$last_install"
    return 0
  end

  # Validate it's a number
  if not string match -rq '^\d+$' $last_install
    return 0
  end

  # Calculate age
  set -l current_time (date +%s)
  set -l age (math $current_time - $last_install)

  # Handle future timestamps (clock skew)
  if test $age -lt 0
    log "Warning: timestamp is in the future, updating fisher"
    return 0
  end

  # Two weeks in seconds
  set -l two_weeks 1209600

  # Check if older than 2 weeks
  if test $age -ge $two_weeks
    set -l days (math "round($age / 86400)")
    log "fisher is $days days old, updating"
    return 0
  else
    set -l days (math "round($age / 86400)")
    log "fisher is up to date (installed $days days ago)"
    return 1
  end
end

function write_fisher_timestamp
  set -l timestamp_file (get_fisher_timestamp_file)
  set -l fisher_state_dir (dirname $timestamp_file)

  # Create state directory if needed
  if not test -d $fisher_state_dir
    if not mkdir -p $fisher_state_dir 2>/dev/null
      log "Warning: Cannot create state directory $fisher_state_dir"
      return 1
    end
  end

  # Write current timestamp
  set -l current_time (date +%s)
  if echo $current_time > $timestamp_file 2>/dev/null
    log "Timestamp recorded: $timestamp_file"
    return 0
  else
    log "Warning: Cannot write timestamp to $timestamp_file"
    return 1
  end
end

function install_or_update_fisher
  log "Installing/updating fisher"
  if curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    if fisher install jorgebucaran/fisher
      write_fisher_timestamp
      return 0
    else
      log "Error: fisher installation failed"
      return 1
    end
  else
    log "Error: failed to download fisher"
    return 1
  end
end

if not type -q curl
  log "curl is required to install fisher"
  exit 1
end

if not type -q fisher
  log "fisher not found, installing"
  install_or_update_fisher
else
  if should_update_fisher
    install_or_update_fisher
  end
end

set plugins jethrokuan/z IlanCosman/tide
for plugin in $plugins
  log "Installing fisher plugin: $plugin"
  fisher install $plugin
  or begin
    log "Warning: Failed to install $plugin. Run 'fisher install $plugin' manually."
  end
end


