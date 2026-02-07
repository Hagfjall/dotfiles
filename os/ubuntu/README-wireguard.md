# WireGuard VPN Setup

This setup provides two main features:
1. **Passwordless VPN connection** - No need to type password when connecting/disconnecting VPN
2. **Status bar indicator** - Shows a VPN icon in i3status-rust when connected

## Prerequisites

- WireGuard must be installed: `sudo apt install wireguard`
- WireGuard configuration must exist at `/etc/wireguard/wg0.conf`

## Installation

### 1. Configure Passwordless Sudo

Run the setup script to install the sudoers configuration:

```bash
sudo ./os/ubuntu/setup-wireguard.sh
```

This allows the `sudo` group to run `wg-quick up/down` commands without password prompt.

### 2. Apply Dotfiles

Run the main install script to link the i3status-rust configuration:

```bash
./install.sh
```

### 3. Reload i3status-rust

Either reload i3/Regolith or run:

```bash
pkill -SIGUSR2 i3status-rust
# or
swaymsg reload
```

## Usage

### Fish Shell Aliases

After setup, you can use these convenient aliases:

```fish
vpn-up       # Connect to VPN (sudo wg-quick up wg0)
vpn-down     # Disconnect from VPN (sudo wg-quick down wg0)
vpn-status   # Show current VPN status
```

### Original Commands

If you prefer, the original commands still work:

```bash
sudo wg-quick up wg0    # No password needed after setup
sudo wg-quick down wg0  # No password needed after setup
```

### Status Bar

When connected to VPN:
- A VPN icon (󰦝) appears in the i3status-rust bar, next to the network indicator
- The icon disappears when VPN is disconnected

## Files

| File | Description |
|------|-------------|
| `os/ubuntu/wireguard-sudoers` | Sudoers.d file for passwordless wg-quick |
| `os/ubuntu/setup-wireguard.sh` | Installer script for sudoers config |
| `apps/i3/vpn-status.sh` | Script that checks VPN status for status bar |
| `home/.config/regolith3/i3status-rust/config.toml` | i3status-rust config with VPN block |
| `home/.config/fish/conf.d/aliases.fish` | Fish aliases including VPN commands |

## Security Notes

- The sudoers configuration only allows `wg-quick up` and `wg-quick down` commands
- Only users in the `sudo` group can use passwordless VPN
- The WireGuard configuration at `/etc/wireguard/wg0.conf` is still protected

## Troubleshooting

### VPN Icon Not Showing

1. Verify VPN is connected:
   ```bash
   ip link show wg0
   ```

2. Test the status script:
   ```bash
   /home/user/git/dotfiles/apps/i3/vpn-status.sh
   ```

3. Reload i3status-rust:
   ```bash
   pkill -SIGUSR2 i3status-rust
   ```

### Passwordless Sudo Not Working

1. Verify sudoers file installed correctly:
   ```bash
   ls -la /etc/sudoers.d/wireguard
   sudo visudo -c
   ```

2. Verify you're in the sudo group:
   ```bash
   groups
   ```
