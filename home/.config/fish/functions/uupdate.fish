function uupdate --description "Update Ubuntu system (apt, snap, cleanup, reboot check)"
    # Set up colored output
    set -l RED (set_color red)
    set -l GREEN (set_color green)
    set -l YELLOW (set_color yellow)
    set -l BLUE (set_color blue)
    set -l NORMAL (set_color normal)

    # Header
    echo "$YELLOW=== Ubuntu System Update ===$NORMAL"
    echo ""

    # Step 1: Update APT package lists
    echo $BLUE"[1/5]"$NORMAL" Updating APT package lists..."
    if sudo apt update
        echo "$GREEN✓ APT update completed$NORMAL"
    else
        echo "$RED✗ APT update failed$NORMAL"
        return 1
    end
    echo ""

    # Step 2: Upgrade APT packages
    echo $BLUE"[2/5]"$NORMAL" Upgrading APT packages..."
    if sudo apt upgrade -y
        echo "$GREEN✓ APT upgrade completed$NORMAL"
    else
        echo "$RED✗ APT upgrade failed$NORMAL"
        return 1
    end
    echo ""

    # Step 3: Update Snap packages
    echo $BLUE"[3/5]"$NORMAL" Refreshing Snap packages..."
    if command -q snap
        if sudo snap refresh
            echo "$GREEN✓ Snap refresh completed$NORMAL"
        else
            echo "$YELLOW⚠ Snap refresh failed (non-critical)$NORMAL"
        end
    else
        echo "$YELLOW⚠ Snap not installed, skipping...$NORMAL"
    end
    echo ""

    # Step 4: Remove unnecessary packages
    echo $BLUE"[4/5]"$NORMAL" Removing unnecessary packages..."
    if sudo apt autoremove -y
        echo "$GREEN✓ Autoremove completed$NORMAL"
    else
        echo "$YELLOW⚠ Autoremove failed (non-critical)$NORMAL"
    end

    if sudo apt autoclean
        echo "$GREEN✓ Autoclean completed$NORMAL"
    else
        echo "$YELLOW⚠ Autoclean failed (non-critical)$NORMAL"
    end
    echo ""

    # Step 5: Check for reboot requirement
    echo $BLUE"[5/5]"$NORMAL" Checking reboot requirement..."
    if test -f /var/run/reboot-required
        echo "$RED┌────────────────────────────────────────┐$NORMAL"
        echo "$RED│  ⚠  SYSTEM REBOOT REQUIRED  ⚠          │$NORMAL"
        echo "$RED└────────────────────────────────────────┘$NORMAL"
        if test -f /var/run/reboot-required.pkgs
            echo "$YELLOW Packages requiring reboot:$NORMAL"
            cat /var/run/reboot-required.pkgs | while read -l pkg
                echo "  - $pkg"
            end
        end
    else
        echo "$GREEN✓ No reboot required$NORMAL"
    end
    echo ""

    echo "$GREEN=== System Update Complete ===$NORMAL"
end
