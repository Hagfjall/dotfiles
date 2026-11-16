# less Syntax Highlighting & Color Coding

This configuration equips `less` with fast, automatic syntax highlighting and color coding for source code files (`.sh`, `.py`, `.js`, `.ts`, `.json`, `.yaml`, `.c`, `.cpp`, `.rs`, `.go`, `.html`, `.css`, `.md`, `Dockerfile`, `Makefile`, and extensionless scripts with shebangs) across Fish, Bash, and Zsh.

## Rust Implementation: `bat`

The filter automatically prefers **`bat`** (the high-performance syntax highlighter written in **Rust**).
- **Speed**: Built on native Rust `syntect` and Sublime syntax definitions — up to 10x faster startup and processing than Python-based highlighters.
- **Light Terminal Themes**: Configured out of the box with the `GitHub` light theme for high contrast and readability on white/light terminal backgrounds.
- **Fallbacks**: If `bat` is not installed, it seamlessly falls back to `pygmentize` (using the light `friendly` style), `highlight` (using `base16/github`), or `source-highlight`.

## How It Works

1. **`LESS="-R"`**: Instructs `less` to pass through ANSI color escape sequences in raw format so colored text renders without control character artifacts.
2. **`lesspipe` integration**: Standard Debian/Ubuntu `lesspipe` is configured as the `LESSOPEN` preprocessor (`LESSOPEN="| /usr/bin/lesspipe %s"`).
3. **`~/.config/lessfilter`**: `lesspipe` invokes `~/.config/lessfilter` before opening files:
   - Identifies source code, configuration files, and text documents.
   - Automatically skips archives (`.tar.gz`, `.zip`, `.deb`, etc.), binary formats, and media so `lesspipe` can decode/list them as usual.
   - Highlighters priority order:
     1. `bat` / `batcat` (Rust)
     2. `pygmentize` (Pygments)
     3. `highlight`
     4. `source-highlight`
4. **Shell Support**:
   - **Fish**: Automatically loaded via `~/.config/fish/conf.d/less.fish`.
   - **Bash**: Configured via `~/.bashrc` / `~/.profile`.
   - **Zsh**: Configured via `~/.zshrc`.

## Installation & Setup

To install highlighters (including `bat` via `apt`) and apply configuration:

```bash
# Run installer (installs packages via apt, then sets up configuration)
bash apps/less/install.sh

# Or apply configuration directly
bash apps/less/setup.sh
```

## Customizing Light & Dark Themes

### For `bat` (Rust):
- Default light theme: `GitHub`
- Recommended alternatives: `Solarized (light)`, `OneHalfLight`, `gruvbox-light`
```bash
# In Bash/Zsh
export BAT_THEME="GitHub"

# In Fish
set -gx BAT_THEME "GitHub"
```

### For `pygmentize`:
- Default light theme: `friendly`
- Recommended alternatives: `tango`, `solarized-light`, `gruvbox-light`, `autumn`
```bash
# In Bash/Zsh
export LESSFILTER_STYLE="friendly"

# In Fish
set -gx LESSFILTER_STYLE "friendly"
```
