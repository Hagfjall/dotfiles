#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running with root privileges
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Error: This script must be run as root${NC}"
    echo "Please use: sudo $0"
    exit 1
fi

echo -e "${YELLOW}=== Ubuntu Hibernation Setup (Dual-Boot) ===${NC}"
echo ""

# ============================================================================
# SECTION 1: PRE-FLIGHT CHECKS
# ============================================================================

echo -e "${BLUE}--- System Information ---${NC}"

# Check if system supports hibernation
echo -n "Checking hibernation support... "
if [[ -f /sys/power/disk ]]; then
    HIBERNATION_SUPPORT=$(cat /sys/power/disk)
    if [[ "$HIBERNATION_SUPPORT" != *"disabled"* ]] || [[ ! -z "$HIBERNATION_SUPPORT" ]]; then
        echo -e "${GREEN}✓ Supported${NC}"
    else
        echo -e "${YELLOW}⚠ May not be available${NC}"
    fi
    echo "  Available modes: $HIBERNATION_SUPPORT"
else
    echo -e "${RED}✗ Not found${NC}"
fi
echo ""

# Detect firmware type
echo -n "Detecting firmware... "
if [[ -d /sys/firmware/efi ]]; then
    FIRMWARE="UEFI"
    echo -e "${GREEN}✓ UEFI${NC}"
else
    FIRMWARE="BIOS"
    echo -e "${BLUE}BIOS (Legacy)${NC}"
fi
echo ""

# Get RAM information
RAM_GB=$(free -h | grep "^Mem:" | awk '{print $2}' | sed 's/G//')
RAM_BYTES=$(free -b | grep "^Mem:" | awk '{print $2}')
echo "Available RAM: ${RAM_GB}GB (${RAM_BYTES} bytes)"
echo ""

# ============================================================================
# SECTION 2: SWAP DETECTION AND CONFIGURATION
# ============================================================================

echo -e "${BLUE}--- Swap Configuration ---${NC}"

# Get swap information
SWAP_OUTPUT=$(swapon --show 2>/dev/null || echo "")

if [[ -z "$SWAP_OUTPUT" ]]; then
    echo -e "${YELLOW}⚠ No swap currently enabled${NC}"
    SWAP_DEVICE=""
    SWAP_SIZE_BYTES=0
else
    echo "Current swap configuration:"
    echo "$SWAP_OUTPUT" | tail -n +2 | while read -r line; do
        echo "  $line"
    done
    echo ""

    # Extract swap device and size
    SWAP_DEVICE=$(echo "$SWAP_OUTPUT" | tail -1 | awk '{print $1}')
    SWAP_SIZE_BYTES=$(echo "$SWAP_OUTPUT" | tail -1 | awk '{print $3}')
fi

if [[ -z "$SWAP_SIZE_BYTES" ]] || [[ "$SWAP_SIZE_BYTES" == "0" ]]; then
    SWAP_SIZE_BYTES=0
    echo "Swap size: 0 (None)"
else
    SWAP_GB=$(echo "scale=2; $SWAP_SIZE_BYTES / 1024 / 1024 / 1024" | bc)
    echo "Swap size: ${SWAP_GB}GB"
fi
echo ""

# Compare swap and RAM
if [[ "$SWAP_SIZE_BYTES" -lt "$RAM_BYTES" ]]; then
    echo -e "${YELLOW}⚠ Warning: Swap (${SWAP_GB}GB) is smaller than RAM (${RAM_GB}GB)${NC}"
    echo "  For full hibernation, swap should be >= RAM"
    echo "  However, partial hibernation is possible with smaller swap"
    echo ""

    read -p "Continue with current swap configuration? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Setup cancelled. Consider:${NC}"
        echo "  1. Create a swap partition/file larger than RAM"
        echo "  2. Run this script again"
        exit 0
    fi
    echo ""
else
    echo -e "${GREEN}✓ Swap size is adequate for full hibernation${NC}"
    echo ""
fi

# ============================================================================
# SECTION 3: IDENTIFY SWAP DEVICE FOR GRUB
# ============================================================================

echo -e "${BLUE}--- Swap Device Detection ---${NC}"

if [[ -n "$SWAP_DEVICE" ]]; then
    echo "Using swap device: $SWAP_DEVICE"

    # Check if it's a swap file or partition
    if [[ "$SWAP_DEVICE" == /* ]] && [[ -f "$SWAP_DEVICE" ]]; then
        echo "Type: Swap file"

        # Calculate resume_offset for swap file
        SWAP_FILE_UUID=$(findmnt -n -o UUID -t tmpfs / 2>/dev/null || echo "")
        if [[ -z "$SWAP_FILE_UUID" ]]; then
            # Try to get UUID from device containing swap file
            SWAP_FILE_DEV=$(df "$SWAP_DEVICE" | tail -1 | awk '{print $1}')
            SWAP_FILE_UUID=$(blkid -s UUID -o value "$SWAP_FILE_DEV" 2>/dev/null || echo "")
        fi

        if [[ -n "$SWAP_FILE_UUID" ]]; then
            echo "Swap file UUID: $SWAP_FILE_UUID"
        fi
    else
        echo "Type: Swap partition"

        # Get UUID of swap partition
        if [[ -b "$SWAP_DEVICE" ]]; then
            SWAP_UUID=$(blkid -s UUID -o value "$SWAP_DEVICE" 2>/dev/null || echo "")
            if [[ -n "$SWAP_UUID" ]]; then
                echo "Swap partition UUID: $SWAP_UUID"
            fi
        fi
    fi
else
    echo -e "${RED}✗ No swap device found${NC}"
    echo ""
    echo -e "${YELLOW}To proceed, you need to create swap. Options:${NC}"
    echo "  1. Create a swap partition (recommended for dual-boot)"
    echo "  2. Create a swap file using this command:"
    echo "     sudo fallocate -l ${RAM_GB}G /swapfile"
    echo "     sudo chmod 600 /swapfile"
    echo "     sudo mkswap /swapfile"
    echo "     sudo swapon /swapfile"
    echo ""
    echo "  Then run this script again."
    exit 0
fi
echo ""

# ============================================================================
# SECTION 4: BACKUP EXISTING CONFIGURATION
# ============================================================================

echo -e "${BLUE}--- Backing Up Configuration Files ---${NC}"

BACKUP_DIR="/root/hibernate-backups-$(date +%Y-%m-%d_%H-%M-%S)"
mkdir -p "$BACKUP_DIR"

# Backup GRUB config
if [[ -f /etc/default/grub ]]; then
    cp /etc/default/grub "$BACKUP_DIR/grub.backup"
    echo -e "${GREEN}✓ Backed up /etc/default/grub${NC}"
else
    echo -e "${YELLOW}⚠ /etc/default/grub not found${NC}"
fi

# Note any existing initramfs config
if [[ -f /etc/initramfs-tools/conf.d/resume ]]; then
    cp /etc/initramfs-tools/conf.d/resume "$BACKUP_DIR/resume.backup"
    echo -e "${GREEN}✓ Backed up resume configuration${NC}"
fi

# Note any existing sleep config
if [[ -d /etc/systemd/sleep.conf.d ]]; then
    if [[ -n "$(ls -A /etc/systemd/sleep.conf.d/ 2>/dev/null)" ]]; then
        cp -r /etc/systemd/sleep.conf.d/ "$BACKUP_DIR/sleep.conf.d.backup/"
        echo -e "${GREEN}✓ Backed up sleep.conf.d directory${NC}"
    fi
fi

echo "Backup location: $BACKUP_DIR"
echo ""

# ============================================================================
# SECTION 5: CONFIGURE GRUB
# ============================================================================

echo -e "${BLUE}--- Configuring GRUB Bootloader ---${NC}"

GRUB_CONFIG="/etc/default/grub"

# Read current GRUB config
if [[ ! -f "$GRUB_CONFIG" ]]; then
    echo -e "${RED}Error: GRUB configuration not found at $GRUB_CONFIG${NC}"
    exit 1
fi

# Extract current GRUB_CMDLINE_LINUX value
if grep -q "^GRUB_CMDLINE_LINUX=" "$GRUB_CONFIG"; then
    CURRENT_CMDLINE=$(grep "^GRUB_CMDLINE_LINUX=" "$GRUB_CONFIG" | cut -d'"' -f2)
else
    CURRENT_CMDLINE=""
fi

# Add resume parameter if not already present
if [[ -n "$SWAP_DEVICE" ]]; then
    if [[ "$SWAP_DEVICE" == /* ]] && [[ -f "$SWAP_DEVICE" ]]; then
        # For swap file, we need both resume device and resume_offset
        SWAP_FILE_DEV=$(df "$SWAP_DEVICE" | tail -1 | awk '{print $1}')
        SWAP_FILE_UUID=$(blkid -s UUID -o value "$SWAP_FILE_DEV" 2>/dev/null || echo "")

        if [[ -n "$SWAP_FILE_UUID" ]]; then
            SWAP_FILE_DEV_UUID="UUID=$SWAP_FILE_UUID"
        else
            SWAP_FILE_DEV_UUID="$SWAP_FILE_DEV"
        fi

        # Calculate resume_offset
        RESUME_OFFSET=$(($(filefrag -v "$SWAP_DEVICE" | grep "^\s*0:" | awk '{print $4}' | cut -d'.' -f1) * 8))

        if [[ -z "$CURRENT_CMDLINE" ]] || [[ ! "$CURRENT_CMDLINE" =~ resume ]]; then
            NEW_CMDLINE="$CURRENT_CMDLINE resume=$SWAP_FILE_DEV_UUID resume_offset=$RESUME_OFFSET"
            NEW_CMDLINE=$(echo "$NEW_CMDLINE" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        else
            NEW_CMDLINE="$CURRENT_CMDLINE"
        fi
    else
        # For swap partition
        SWAP_UUID=$(blkid -s UUID -o value "$SWAP_DEVICE" 2>/dev/null || echo "$SWAP_DEVICE")

        if [[ -z "$CURRENT_CMDLINE" ]] || [[ ! "$CURRENT_CMDLINE" =~ resume ]]; then
            NEW_CMDLINE="$CURRENT_CMDLINE resume=UUID=$SWAP_UUID"
            NEW_CMDLINE=$(echo "$NEW_CMDLINE" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        else
            NEW_CMDLINE="$CURRENT_CMDLINE"
        fi
    fi

    # Update GRUB config
    sed -i "s/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX=\"$NEW_CMDLINE\"/" "$GRUB_CONFIG"
    echo -e "${GREEN}✓ Updated GRUB kernel parameters${NC}"
    echo "  resume=$SWAP_DEVICE"
    if [[ -v RESUME_OFFSET ]]; then
        echo "  resume_offset=$RESUME_OFFSET"
    fi
fi
echo ""

# ============================================================================
# SECTION 6: CONFIGURE INITRAMFS
# ============================================================================

echo -e "${BLUE}--- Configuring Initramfs ---${NC}"

RESUME_CONFIG="/etc/initramfs-tools/conf.d/resume"
mkdir -p "$(dirname "$RESUME_CONFIG")"

if [[ -n "$SWAP_DEVICE" ]]; then
    if [[ -f "$SWAP_DEVICE" ]]; then
        # Swap file
        SWAP_FILE_DEV=$(df "$SWAP_DEVICE" | tail -1 | awk '{print $1}')
        SWAP_FILE_UUID=$(blkid -s UUID -o value "$SWAP_FILE_DEV" 2>/dev/null || echo "")
        RESUME_DEV="UUID=$SWAP_FILE_UUID"
        RESUME_OFFSET=$(($(filefrag -v "$SWAP_DEVICE" | grep "^\s*0:" | awk '{print $4}' | cut -d'.' -f1) * 8))

        cat > "$RESUME_CONFIG" << EOF
# Hibernation resume configuration
# Generated by setup-hibernate.sh
RESUME=$RESUME_DEV
RESUME_OFFSET=$RESUME_OFFSET
EOF
    else
        # Swap partition
        SWAP_UUID=$(blkid -s UUID -o value "$SWAP_DEVICE" 2>/dev/null || echo "$SWAP_DEVICE")

        cat > "$RESUME_CONFIG" << EOF
# Hibernation resume configuration
# Generated by setup-hibernate.sh
RESUME=UUID=$SWAP_UUID
EOF
    fi

    echo -e "${GREEN}✓ Created resume configuration${NC}"
    echo "  Location: $RESUME_CONFIG"
fi

echo "Rebuilding initramfs..."
if update-initramfs -u -k all > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Initramfs rebuilt successfully${NC}"
else
    echo -e "${YELLOW}⚠ Initramfs rebuild returned an error (this may be expected)${NC}"
fi
echo ""

# ============================================================================
# SECTION 7: CONFIGURE SYSTEMD SLEEP SETTINGS
# ============================================================================

echo -e "${BLUE}--- Configuring systemd Sleep Settings ---${NC}"

SLEEP_CONFIG_DIR="/etc/systemd/sleep.conf.d"
SLEEP_CONFIG_FILE="$SLEEP_CONFIG_DIR/hibernate.conf"

mkdir -p "$SLEEP_CONFIG_DIR"

cat > "$SLEEP_CONFIG_FILE" << EOF
# Hibernation settings
# Generated by setup-hibernate.sh
# https://man7.org/linux/man-pages/man5/systemd-sleep.conf.5.html

[Sleep]
# State to enter for suspend (mem = S3 state)
SuspendState=mem

# How to enter hibernation
# Options: platform (recommended), shutdown, reboot
HibernateMode=platform

# Hybrid sleep: suspend to RAM but also write to disk for recovery
HybridSleepMode=platform

# Enable hybrid sleep (suspend-then-hibernate)
HybridSleep=no
EOF

echo -e "${GREEN}✓ Created sleep configuration${NC}"
echo "  Location: $SLEEP_CONFIG_FILE"
echo ""

# ============================================================================
# SECTION 8: ENABLE HIBERNATE IN LOGIND
# ============================================================================

echo -e "${BLUE}--- Enabling Hibernation in systemd-logind ---${NC}"

LOGIND_CONFIG="/etc/systemd/logind.conf"

if [[ -f "$LOGIND_CONFIG" ]]; then
    # Check if HandleLidSwitch is already set to hibernate
    if grep -q "^#.*HandleLidSwitch" "$LOGIND_CONFIG" && ! grep -q "^HandleLidSwitch=hibernate" "$LOGIND_CONFIG"; then
        echo "Note: You can enable hibernation on lid close by setting:"
        echo "  HandleLidSwitch=hibernate"
        echo "  in $LOGIND_CONFIG"
    fi
fi
echo ""

# ============================================================================
# SECTION 9: DUAL-BOOT WARNINGS
# ============================================================================

echo -e "${YELLOW}=== IMPORTANT: Dual-Boot Considerations ===${NC}"
echo ""
echo -e "${YELLOW}⚠ Windows Hibernation Conflict:${NC}"
echo "  • Hibernating Linux while Windows has hibernate enabled can cause issues"
echo "  • Shut down Windows completely before hibernating"
echo "  • Do NOT use Windows hibernation on this dual-boot system"
echo ""
echo -e "${YELLOW}⚠ EFI Boot Order:${NC}"
echo "  • This script only modifies Linux-side GRUB configuration"
echo "  • Your Windows partition and EFI boot order are NOT changed"
echo "  • GRUB will still be your boot manager"
echo ""

# ============================================================================
# SECTION 10: VERIFICATION
# ============================================================================

echo -e "${BLUE}--- Configuration Summary ---${NC}"
echo "Backup directory: $BACKUP_DIR"
echo "GRUB config: $GRUB_CONFIG"
echo "Resume config: $RESUME_CONFIG"
echo "Sleep config: $SLEEP_CONFIG_FILE"
echo ""

# ============================================================================
# SECTION 11: NEXT STEPS
# ============================================================================

echo -e "${GREEN}✓ Hibernation setup complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo "1. Reboot your system to apply GRUB changes:"
echo "   sudo reboot"
echo ""
echo "2. After reboot, test hibernation:"
echo "   sudo systemctl hibernate"
echo ""
echo "3. Your system should write to disk and power off"
echo "4. Power on and verify it resumes from hibernation"
echo ""
echo -e "${YELLOW}Manual verification commands:${NC}"
echo "  Check if hibernation is available:"
echo "    cat /sys/power/disk"
echo "  Check if resume device is set:"
echo "    cat /proc/cmdline | grep resume"
echo "  Check sleep configuration:"
echo "    cat $SLEEP_CONFIG_FILE"
echo ""

# ============================================================================
# ROLLBACK INSTRUCTIONS
# ============================================================================

echo -e "${YELLOW}Rollback Instructions:${NC}"
echo "If hibernation doesn't work, restore your original configuration:"
echo ""
echo "  1. Boot from live USB or recovery"
echo "  2. Mount your root filesystem"
echo "  3. Restore from backup:"
echo "    sudo cp $BACKUP_DIR/grub.backup /etc/default/grub"
echo "    sudo rm -f /etc/initramfs-tools/conf.d/resume"
echo "    sudo update-grub"
echo "    sudo update-initramfs -u"
echo ""
echo "  4. Reboot"
echo ""

echo -e "${YELLOW}Backup location for reference:${NC}"
echo "  $BACKUP_DIR"
echo ""

exit 0
