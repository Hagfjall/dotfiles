# CopyQ Clipboard Manager

CopyQ is a feature-rich clipboard manager for Linux that maintains a history of your clipboard items (CTRL+C copies) and allows quick access via hotkey.

## Features

- **Clipboard History**: Keeps last 200+ clipboard items (well above the 10-item minimum)
- **Quick Access**: Press Ctrl+Shift+V to open clipboard history
- **Clean Paste**: Paste without formatting using Ctrl+Shift+P
- **Autostart**: Automatically runs on system boot
- **System Tray**: Minimizes to system tray for easy access
- **Wayland Compatible**: Works with your Wayland/GNOME/Regolith setup
- **Lightweight**: Minimal resource usage

## Installation

### Step 1: Install the Package

```bash
sudo ./install.sh
```

This script will:
- Check if CopyQ is already installed
- Update package list
- Install CopyQ from Ubuntu repositories
- Verify the installation

### Step 2: Configure CopyQ

```bash
./setup.sh
```

This script will:
- Create the configuration directory
- Install the configuration file with optimal settings
- Set up autostart on system boot
- Start CopyQ immediately
- Create a backup of any existing configuration

## Usage

### Primary Hotkeys

| Hotkey | Action |
|--------|--------|
| Ctrl+Shift+V | Open clipboard history menu |
| Ctrl+Shift+P | Paste without formatting |
| Ctrl+Alt+A | Show action menu |
| Ctrl+E | Edit selected item |
| Delete | Delete selected item from history |
| Ctrl+Shift+Delete | Clear entire clipboard history |

### Workflow

1. **Copy items normally**: Use Ctrl+C as usual. CopyQ monitors your clipboard automatically.
2. **Access history**: Press Ctrl+Shift+V to open the history menu
3. **Select and paste**: Click on any item in the list to paste it
4. **Clean paste**: Use Ctrl+Shift+P to paste without formatting (removes styles, colors, etc.)

### System Tray

CopyQ runs in the system tray. You can:
- Click the CopyQ icon to show/hide the main window
- Right-click for menu options
- Access clipboard items directly from the tray menu

## Configuration

The configuration file is located at `~/.config/copyq/copyq.conf`

### Key Settings

- `max_items=25` - Maximum number of items in history (increase for more)
- `autostart=true` - Start automatically on boot
- Global hotkey mappings in the `[Shortcuts]` section

### Customizing Hotkeys

Edit `~/.config/copyq/copyq.conf` and modify the `[Shortcuts]` section:

```ini
[Shortcuts]
show=Ctrl+Shift+V
paste_without_formatting=Ctrl+Shift+P
```

Available modifiers: `shift`, `ctrl`, `alt`, `meta`

To apply changes, restart CopyQ:
```bash
killall copyq
copyq &
```

## Troubleshooting

### CopyQ not starting

If CopyQ doesn't start automatically:
```bash
copyq &
```

### Clear clipboard history

```bash
# Open CopyQ menu
copyq show

# Press Ctrl+Shift+Delete or use the menu
```

### Check if CopyQ is running

```bash
pgrep copyq
```

### View CopyQ logs

CopyQ stores logs in `~/.config/copyq/`

## Backup and Restore

If you need to restore a previous configuration:
```bash
# Backup was created at:
~/.config/copyq/copyq.conf.backup.<date>

# To restore:
cp ~/.config/copyq/copyq.conf.backup.<date> ~/.config/copyq/copyq.conf
killall copyq
copyq &
```

## Uninstall

To completely remove CopyQ:

```bash
# Stop CopyQ
killall copyq

# Remove autostart
rm ~/.config/autostart/copyq.desktop

# Uninstall package
sudo apt-get remove copyq

# Optional: Remove configuration
rm -rf ~/.config/copyq/
```

## Performance Notes

- CopyQ uses minimal CPU/memory overhead
- Clipboard monitoring is efficient
- Works well with Wayland on GNOME/Regolith
- History is kept in memory (not persisted across reboots by default)

## Further Reading

- [CopyQ GitHub](https://github.com/hluk/CopyQ)
- [CopyQ User Manual](https://hluk.github.io/CopyQ/)
