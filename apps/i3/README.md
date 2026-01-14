# Display Switcher for i3/Regolith

A Windows-style WIN+P display mode switcher for Ubuntu with i3/Regolith Desktop. Quickly switch between laptop screen only, external monitor only, or extended desktop modes using Super+P.

## Features

- **Quick Display Switching**: Press Super+P to open a menu with display options
- **Auto-Detection**: Automatically detects laptop and external displays
- **Three Display Modes**:
  - Laptop screen only
  - External monitor only
  - Extended desktop (displays side by side)
- **Desktop Notifications**: Get visual feedback when switching modes
- **Idempotent Setup**: Safe to run setup multiple times
- **Regolith/i3 Integration**: Native integration with i3 window manager

## Requirements

- Ubuntu with i3 window manager or Regolith Desktop
- xrandr (usually pre-installed with X11)
- rofi (will be installed by setup script)

## Installation

### Step 1: Install Dependencies

```bash
cd apps/i3
sudo ./install.sh
```

This installs:
- `rofi` - Menu system for display selection
- `x11-xserver-utils` - Contains xrandr for display management
- `libnotify-bin` - For desktop notifications

### Step 2: Configure Display Switcher

```bash
./setup.sh
```

This:
- Installs the display switcher script to `~/.local/bin/`
- Backs up your existing i3 config (if present)
- Adds the Super+P keyboard shortcut to your i3 config
- Reloads i3 configuration

## Usage

### Basic Usage

Press **Super+P** (Windows key + P) to open the display mode selector:

```
┌─────────────────────────────────────┐
│ Display Mode (Super+P)              │
├─────────────────────────────────────┤
│ ▪ Laptop only                       │
│   External only                     │
│   Extended desktop                  │
└─────────────────────────────────────┘
```

Use arrow keys or mouse to select a mode, then press Enter to apply.

### Display Modes Explained

**Laptop only**
- Uses only the built-in laptop screen
- All external monitors are disabled
- Useful for portable work or when docking out

**External only**
- Uses only the external monitor
- Disables the laptop screen
- Good for presentations or desk setup with large display

**Extended desktop**
- Uses both laptop and external displays
- External monitor is positioned to the right of the laptop screen
- Maximum workspace (perfect for productivity)

## Configuration

### Change the Keyboard Shortcut

To use a different keyboard shortcut:

1. Edit your i3 config:
   ```bash
   nano ~/.config/i3/config
   ```

2. Find the line with `display-switcher` (added at the end)

3. Change `$mod+p` to your preferred key combination:
   ```bash
   bindsym $mod+o exec --no-startup-id ~/.local/bin/display-switcher
   ```

4. Reload i3:
   ```bash
   i3-msg reload
   ```

### Change Display Positioning

To position external monitor differently (e.g., left of laptop instead of right):

1. Edit the display switcher script:
   ```bash
   nano ~/.local/bin/display-switcher
   ```

2. Find the `mode_extended()` function and change `--right-of` to:
   - `--left-of` - External monitor on left
   - `--above` - External monitor above
   - `--below` - External monitor below

3. Save and test with Super+P

### Set Custom Resolution

To use a specific resolution instead of auto-detection:

1. Check available resolutions:
   ```bash
   xrandr --query
   ```

2. Edit `~/.local/bin/display-switcher` and modify the mode functions, for example:
   ```bash
   xrandr --output HDMI-1 --mode 1920x1080 --rate 60 --right-of eDP-1
   ```

## Troubleshooting

### Display Menu Doesn't Appear

1. Check if rofi is installed:
   ```bash
   rofi -version
   ```

2. If not installed, run:
   ```bash
   sudo apt-get install rofi
   ```

3. Test the script manually:
   ```bash
   ~/.local/bin/display-switcher
   ```

### Detect Your Display Names

To see what displays are available on your system:

```bash
xrandr --query
```

Output shows connected displays. Common names:
- Laptop displays: `eDP-1`, `eDP1`, `LVDS-1`
- HDMI monitors: `HDMI-1`, `HDMI-2`
- DisplayPort: `DP-1`, `DP-2`

### Restore from Backup

If something goes wrong, restore your previous i3 config:

```bash
# Find the backup file (they're timestamped)
ls -la ~/.config/i3/config.backup.*

# Restore from a specific backup
cp ~/.config/i3/config.backup.2024-01-15_10-30-45 ~/.config/i3/config

# Reload i3
i3-msg reload
```

### Permissions Issues

If the script can't be executed:

```bash
chmod +x ~/.local/bin/display-switcher
```

### No External Monitor Detected

When no external monitor is connected, only "Laptop only" mode is offered. Connect an external monitor to see additional options.

## Advanced Usage

### Multi-Monitor Setup

The script currently handles the first external monitor. For multiple external monitors, you can:

1. Manually edit `~/.local/bin/display-switcher`
2. Modify the `mode_extended()` function to include additional displays
3. Example for two external monitors:
   ```bash
   xrandr --output eDP-1 --auto --primary \
           --output HDMI-1 --auto --right-of eDP-1 \
           --output DP-1 --auto --right-of HDMI-1
   ```

### Manual Display Commands

If you prefer manual control, use xrandr directly:

```bash
# Get current state
xrandr --query

# Laptop only
xrandr --output eDP-1 --auto --primary --output HDMI-1 --off

# External only
xrandr --output eDP-1 --off --output HDMI-1 --auto --primary

# Extended (right)
xrandr --output eDP-1 --auto --primary --output HDMI-1 --auto --right-of eDP-1

# Set custom resolution
xrandr --output HDMI-1 --mode 3840x2160 --rate 60

# Rotate display
xrandr --output HDMI-1 --rotate left
```

## Uninstallation

To remove the display switcher:

```bash
# Remove the script
rm ~/.local/bin/display-switcher

# Remove keybinding from i3 config (optional)
nano ~/.config/i3/config
# Remove the display-switcher lines at the end

# Reload i3
i3-msg reload

# (Optional) Remove packages if you don't need them
sudo apt-get remove rofi
```

## Contributing

Found a bug or have a suggestion? Check the main repository's issues section.

## License

Part of the dotfiles repository.
