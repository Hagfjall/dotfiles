# tmux Configuration

This directory provides installation and setup scripts for tmux with dotfiles integration.

## Features

- **Inherit Current Working Directory**: Opening a new window (`Prefix + c`) or splitting a pane (`Prefix + %`, `"`, `|`, `\`, `-`, `_`) retains the current working directory (`#{pane_current_path}`) of the active pane.
- **Intuitive & Standard Splits**:
  - Horizontal split (side-by-side): `Prefix + %`, `Prefix + |`, or `Prefix + \`
  - Vertical split (top/bottom): `Prefix + "`, `Prefix + -`, or `Prefix + _`
- **Pane Navigation**: `Alt + Arrow keys` (Left, Right, Up, Down) without needing the prefix key.
- **Config Reload**: `Prefix + r` reloads `~/.tmux.conf` on the fly.
- **Mouse Support**: Mouse selection, pane resizing, and scrolling enabled.
- **Terminal & Colors**: 256 colors and RGB true-color support.

## Installation & Setup

### Option 1: Via Main Dotfiles Installer

Running the main dotfiles installer will automatically link `.tmux.conf` and configure tmux:

```bash
./install.sh
```

### Option 2: Standalone Setup

To configure tmux without re-running the full dotfiles suite:

```bash
./setup.sh
```

To install the tmux package and configure it:

```bash
./install.sh
```

## Configuration File

The primary tmux configuration is stored in `home/.tmux.conf` and symlinked to `~/.tmux.conf`.
