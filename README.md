# 👁 Eye Guard CLI

> Automatic light/dark theme synchronizer for CLI applications on Linux.

Eye Guard CLI listens for system-level colour scheme changes (via D-Bus) and instantly propagates them to your terminal tools — bat, foot, Neovim, Zellij, and more — through a modular plugin system.

---

## Features

- **Automatic switching** — listens to `org.freedesktop.portal.Settings` D-Bus signals; no manual intervention needed
- **Modular plugins** — each supported tool is an independent script; add or remove plugins without touching core logic
- **Persistent state** — current mode is cached so plugins can query it at any time
- **systemd integration** — runs as a user service, starts with your graphical session
- **Interactive installer** — TUI-driven setup powered by [gum](https://github.com/charmbracelet/gum), with smart defaults and config detection

---

## Supported Applications

| Plugin | Detection | Dark default | Light default |
|--------|-----------|-------------|---------------|
| [bat](https://github.com/sharkdp/bat) | `bat` on `$PATH` | `Monokai Extended` | `Monokai Extended Light` |
| [foot](https://codeberg.org/dnkl/foot) | `foot` on `$PATH` | `[colors]` block | `[colors2]` block |
| [Neovim](https://neovim.io) | `nvim` on `$PATH` | `habamax` | `morning` |
| [Zellij](https://zellij.dev) | `zellij` on `$PATH` | `gruvbox-dark` | `gruvbox-light` |
| [Alacritty](https://alacritty.org) | `alacritty` on `$PATH` | `gruvbox_dark` | `gruvbox_light` |
| [kitty](https://sw.kovidgoyal.net/kitty) | `kitty` on `$PATH` | `Gruvbox Dark` | `Gruvbox Light` |
| [Ghostty](https://ghostty.org/) | `ghostty` on `$PATH` | `Gruvbox Dark` | `Gruvbox Light` |

---

## Requirements

- Linux with a desktop portal supporting `org.freedesktop.portal.Settings` (GNOME, KDE, etc.)
- `dbus-monitor` (part of `dbus`)
- `systemd` (user session)
- [gum](https://github.com/charmbracelet/gum) — for the installer TUI
- `bash` ≥ 4.0

---

## Installation

Clone the repository anywhere you like — the installer will copy the project to `~/.local/share/eye-guard-cli` automatically.

```bash
git clone https://github.com/your-username/eye-guard-cli.git
cd eye-guard-cli
chmod +x install.sh
./install.sh
```

The installer will:

1. Detect which supported tools are installed on your system
2. Present a checkbox list of plugins to enable (detected tools are pre-selected)
3. Optionally walk you through configuring each plugin interactively
4. Preview the generated config file and write it to `~/.config/eye-guard-cli/config.env`
5. Copy the project to `~/.local/share/eye-guard-cli`
6. Symlink `eye-guard-cli` and `eye-guard-listener.sh` into `~/.local/bin`
7. Install and start the systemd user service

> **Note:** Make sure `~/.local/bin` is on your `$PATH`.

---

## Uninstallation

```bash
./install.sh uninstall
```

This removes the install directory, binary symlinks, and systemd service. Your configuration file at `~/.config/eye-guard-cli/config.env` is intentionally left intact.

---

## Configuration

The config file lives at `~/.config/eye-guard-cli/config.env` and is a plain bash env file:

```bash
BAT_DARK_THEME="Monokai Extended"
BAT_LIGHT_THEME="Monokai Extended Light"
# foot: themes are defined as [colors] and [colors2] in ~/.config/foot/foot.ini
NVIM_DARK_THEME="habamax"
NVIM_LIGHT_THEME="morning"
ZELLIJ_DARK_THEME="gruvbox-dark"
ZELLIJ_LIGHT_THEME="gruvbox-light"
```

You can edit it manually at any time. Re-running `./install.sh` will detect the existing config and only prompt for newly added plugins.

### foot

foot uses POSIX signals rather than theme name variables. Define your two palettes directly in `~/.config/foot/foot.ini`:

```ini
[colors]
# your dark palette here

[colors2]
# your light palette here
```

Eye Guard CLI sends `SIGUSR1` for dark mode (reloads `[colors]`) and `SIGUSR2` for light mode (switches to `[colors2]`).

### Ghostty

Ghostty handles dark/light switching natively via its `theme` config key:

​```
theme = light:"Gruvbox Light",dark:"Gruvbox Dark"
​```

The installer writes this line during setup. The runtime plugin only sends a
reload signal — Ghostty itself decides which theme to apply based on the
current system appearance.

### Alacritty

Alacritty hot-reloads its config automatically. The plugin manages a dedicated
`~/.config/alacritty/current-theme.toml` file and swaps the import on each
switch. Your main `alacritty.toml` must include it:

​```toml
[general]
import = ["~/.config/alacritty/current-theme.toml"]
​```

The installer adds this line automatically if it is not already present.

---

## Usage

```
eye-guard-cli <command> [args]

Commands:
  set dark     Switch all plugins to dark mode
  set light    Switch all plugins to light mode
  status       Print the current mode
  reload       Re-apply the current mode to all plugins
  help         Show this help message
```

In normal use you never need to call `eye-guard-cli` directly — the listener service handles it. Manual invocation is useful for testing or scripting.

---

## Project Structure

```
eye-guard-cli/
├── core/
│   └── utils.sh                 # Shared helpers: log(), update_state(), load_config()
├── plugins/
│   ├── bat.sh                   # bat runtime plugin
│   ├── bat.install.sh           # bat installer sidecar
│   ├── ...
│   ├── zellij.sh                # Zellij runtime plugin
│   └── zellij.install.sh        # Zellij installer sidecar
├── eye-guard-cli                # Main dispatcher script
├── eye-guard-listener.sh        # D-Bus listener (runs as systemd service)
├── eye-guard.service            # systemd user service unit
├── install.sh                   # Installer / uninstaller
└── README.md
```

### Adding a plugin

1. Create `plugins/<name>.sh` — receives `dark` or `light` as `$1`, applies the theme.
2. Create `plugins/<name>.install.sh` — receives `true`/`false` (interactive mode) as `$1`, outputs `KEY="value"` lines to stdout.
3. Add `<name>` to the `ALL_PLUGINS` array in `install.sh`.

The runtime dispatcher and installer will pick up the new plugin automatically.

---

## How it works

```
D-Bus signal (org.freedesktop.appearance)
        │
        ▼
eye-guard-listener.sh
  translates 1 → "dark", 2 → "light"
  calls: eye-guard-cli set <mode>
        │
        ▼
eye-guard-cli
  updates ~/.cache/eye-guard-cli/current_mode
  spawns each plugin in an isolated subshell
        │
        ├── plugins/bat.sh <mode>
        ├── plugins/foot.sh <mode>
        ├── plugins/nvim.sh <mode>
        └── plugins/zellij.sh <mode>
```

Each plugin runs independently — a failure in one does not affect the others. Results are logged individually to journald.

---

## Logs

Since the listener runs as a systemd service, all output goes to the journal:

```bash
journalctl --user -u eye-guard.service -f
```

---

## A note on how this was built

This project was developed using **vibe coding** — an AI-assisted workflow where a developer iterates rapidly with a large language model (Claude, in this case), describing intent in natural language and refining the output through conversation rather than writing every line by hand.

Vibe coding is a legitimate and increasingly common development approach, but it comes with trade-offs worth being honest about. The initial implementation was functional but inconsistent — variable naming collisions, magic numbers, functions defined but never called, config files being accidentally sourced as shell scripts. None of these were caught before running the code.

The project reached its current state through a deliberate second pass: auditing every file for correctness, aligning on conventions (named modes over numeric D-Bus values, subshells over sourcing, structured dispatch over ad-hoc argument handling), and refactoring the architecture to be properly modular before writing the installer.

The lesson is not that vibe coding is unreliable — it is remarkably fast for getting a working skeleton. The lesson is that **vibe coding without review is unfinished work**. Treat AI-generated code the way you would treat code from a very fast junior developer: read it, question it, and make it yours before shipping it.

---

## License

MIT — see [LICENSE](LICENSE).
