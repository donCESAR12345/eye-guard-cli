#!/bin/bash

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$BASE_DIR/core/utils.sh"

# ─── Constants ────────────────────────────────────────────────────────────────

INSTALL_DIR="$HOME/.local/share/eye-guard-cli"
INSTALL_BIN="$HOME/.local/bin/eye-guard-cli"
INSTALL_LISTENER="$HOME/.local/bin/eye-guard-listener.sh"
SERVICE_DIR="$HOME/.config/systemd/user"
SERVICE_DEST="$SERVICE_DIR/eye-guard.service"
DEFAULT_CONFIG_PATH="$HOME/.config/eye-guard-cli/config.env"

# All plugins the system knows about, in order
ALL_PLUGINS=(bat foot nvim zellij)

# ─── Helpers ──────────────────────────────────────────────────────────────────

require_gum() {
    if ! command -v gum &> /dev/null; then
        echo "Error: gum is required but not installed." >&2
        echo "Install it from https://github.com/charmbracelet/gum" >&2
        exit 1
    fi
}

is_installed() {
    command -v "$1" &> /dev/null
}

# ─── Step 1: Header ───────────────────────────────────────────────────────────

show_header() {
    gum style \
        --border double \
        --border-foreground 212 \
        --padding "1 4" \
        --margin "1 2" \
        --bold \
        "👁  Eye Guard CLI" \
        "" \
        "Automatic light/dark theme switcher"
}

# ─── Step 2: Detect installed tools ───────────────────────────────────────────

# Sets DETECTED_PLUGINS to the subset of ALL_PLUGINS that are on $PATH.
detect_plugins() {
    DETECTED_PLUGINS=()
    for plugin in "${ALL_PLUGINS[@]}"; do
        if is_installed "$plugin"; then
            DETECTED_PLUGINS+=("$plugin")
        fi
    done
}

# ─── Step 3: Plugin selection ─────────────────────────────────────────────────

# Sets SELECTED_PLUGINS from a gum choose checkbox.
# Detected plugins are pre-selected; others appear unselected at the bottom.
select_plugins() {
    local recommended=()
    local others=()

    for plugin in "${ALL_PLUGINS[@]}"; do
        local found=false
        for detected in "${DETECTED_PLUGINS[@]}"; do
            [[ "$plugin" == "$detected" ]] && found=true && break
        done
        if $found; then
            recommended+=("$plugin")
        else
            others+=("$plugin")
        fi
    done

    gum style --bold --margin "0 2" "Select plugins to configure:"
    gum style --faint --margin "0 2" "Installed tools are pre-selected. Use Space to toggle, Enter to confirm."
    echo ""

    # Build the argument list: recommended first (--selected), then others
    local gum_args=()
    for p in "${recommended[@]}"; do
        gum_args+=("--selected=$p")
    done

    local all_options=("${recommended[@]}" "${others[@]}")

    local chosen
    chosen=$(gum choose \
        --no-limit \
        "${gum_args[@]}" \
        "${all_options[@]}")

    if [[ -z "$chosen" ]]; then
        gum style --foreground 196 "No plugins selected. Aborting."
        exit 0
    fi

    mapfile -t SELECTED_PLUGINS <<< "$chosen"
}

# ─── Step 4: Interactive config ───────────────────────────────────────────────

# Usage: plugin_is_configured <plugin>
# Returns 0 if the plugin already has entries in the existing config, 1 if not.
plugin_is_configured() {
    local plugin="$1"
    [[ -f "$DEFAULT_CONFIG_PATH" ]] || return 1

    if [[ "$plugin" == "foot" ]]; then
        grep -q "^# foot:" "$DEFAULT_CONFIG_PATH"
    else
        grep -qi "^${plugin}_" "$DEFAULT_CONFIG_PATH"
    fi
}

# Sets CONFIG_LINES and CONFIG_CHANGED.
run_plugin_installers() {
    CONFIG_LINES=()
    CONFIG_CHANGED=false

    # Load existing config lines as the baseline, if present
    if [[ -f "$DEFAULT_CONFIG_PATH" ]]; then
        mapfile -t CONFIG_LINES < "$DEFAULT_CONFIG_PATH"
    fi

    # Determine which selected plugins are missing from the current config
    local unconfigured=()
    for plugin in "${SELECTED_PLUGINS[@]}"; do
        if ! plugin_is_configured "$plugin"; then
            unconfigured+=("$plugin")
        fi
    done

    # If all plugins are already configured, nothing to do
    if [[ ${#unconfigured[@]} -eq 0 ]]; then
        gum style --faint --margin "0 2" \
            "All selected plugins are already configured. Skipping."
        return
    fi

    # At least one new plugin — ask about interactive mode, then run sidecars
    echo ""
    gum style --bold --foreground 214 --margin "0 2" \
        "New plugins to configure: ${unconfigured[*]}"
    echo ""
    gum style --bold --margin "0 2" "Configuration mode:"

    if gum confirm "Configure each new plugin interactively?"; then
        INTERACTIVE=true
    else
        INTERACTIVE=false
        gum style --faint --margin "0 2" \
            "Using defaults. You can edit $DEFAULT_CONFIG_PATH at any time."
    fi

    for plugin in "${unconfigured[@]}"; do
        local sidecar="$BASE_DIR/plugins/$plugin.install.sh"

        if [[ ! -f "$sidecar" ]]; then
            gum style --foreground 214 --margin "0 2" \
                "Warning: no installer found for plugin '$plugin', skipping."
            continue
        fi

        echo ""
        gum style --bold --margin "0 2" "── $plugin ──"

        local output
        output=$(bash "$sidecar" "$INTERACTIVE")

        if [[ $? -ne 0 || -z "$output" ]]; then
            gum style --foreground 196 --margin "0 2" \
                "Error: installer for '$plugin' failed, skipping."
            continue
        fi

        while IFS= read -r line; do
            CONFIG_LINES+=("$line")
        done <<< "$output"

        CONFIG_CHANGED=true
    done
}

# ─── Step 5: Preview and write config ─────────────────────────────────────────

preview_and_write_config() {
    # Nothing to write if config didn't change
    if [[ "$CONFIG_CHANGED" == "false" ]]; then
        return
    fi

    local config_content
    config_content=$(printf "%s\n" "${CONFIG_LINES[@]}")

    echo ""
    gum style --bold --margin "0 2" "Resulting configuration:"
    echo ""
    gum style \
        --border rounded \
        --border-foreground 240 \
        --padding "1 2" \
        --margin "0 2" \
        "$config_content"

    echo ""
    gum style --bold --margin "0 2" "Where should the config file be written?"

    local config_path
    config_path=$(gum input \
        --placeholder "$DEFAULT_CONFIG_PATH" \
        --value "$DEFAULT_CONFIG_PATH")

    config_path="${config_path:-$DEFAULT_CONFIG_PATH}"

    mkdir -p "$(dirname "$config_path")"
    printf "%s\n" "${CONFIG_LINES[@]}" > "$config_path"

    gum style --foreground 82 "✓ Config written to $config_path"
    WRITTEN_CONFIG_PATH="$config_path"
}

# ─── Install: binary symlinks and systemd service ─────────────────────────────

install_system_files() {
    echo ""
    gum style --bold --margin "0 2" "Installing system files..."

    # Copy the full project to the install location, excluding installer sidecars
    # and git metadata which are not needed at runtime
    rm -rf "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
    cp -r "$BASE_DIR/core"    "$INSTALL_DIR/"
    cp -r "$BASE_DIR/plugins" "$INSTALL_DIR/"
    cp    "$BASE_DIR/eye-guard-cli"         "$INSTALL_DIR/"
    cp    "$BASE_DIR/eye-guard-listener.sh" "$INSTALL_DIR/"
    cp    "$BASE_DIR/eye-guard.service"     "$INSTALL_DIR/"
    gum style --foreground 82 "✓ Project copied to $INSTALL_DIR"

    # Symlink the binaries into $PATH
    mkdir -p "$(dirname "$INSTALL_BIN")"
    ln -sf "$INSTALL_DIR/eye-guard-cli" "$INSTALL_BIN"
    gum style --foreground 82 "✓ Linked eye-guard-cli → $INSTALL_BIN"

    ln -sf "$INSTALL_DIR/eye-guard-listener.sh" "$INSTALL_LISTENER"
    gum style --foreground 82 "✓ Linked eye-guard-listener.sh → $INSTALL_LISTENER"

    # Install the systemd service
    mkdir -p "$SERVICE_DIR"
    cp "$INSTALL_DIR/eye-guard.service" "$SERVICE_DEST"
    gum style --foreground 82 "✓ Installed systemd service → $SERVICE_DEST"

    # Reload and enable
    systemctl --user daemon-reload
    systemctl --user enable --now eye-guard.service
    gum style --foreground 82 "✓ Service enabled and started"
}

# ─── Install: main flow ───────────────────────────────────────────────────────

cmd_install() {
    show_header
    detect_plugins
    select_plugins
    ask_interactive
    run_plugin_installers
    preview_and_write_config
    install_system_files

    echo ""
    gum style \
        --border rounded \
        --border-foreground 82 \
        --padding "1 3" \
        --margin "1 2" \
        --bold \
        "✓ Eye Guard CLI installed successfully!" \
        "" \
        "Run 'eye-guard-cli help' to get started."
}

# ─── Uninstall ────────────────────────────────────────────────────────────────

cmd_uninstall() {
    show_header

    echo ""
    gum style --bold --foreground 196 --margin "0 2" \
        "This will remove all Eye Guard CLI system files."
    gum style --faint --margin "0 2" \
        "Your config at $DEFAULT_CONFIG_PATH will not be touched."
    echo ""

    if ! gum confirm "Proceed with uninstall?"; then
        gum style --faint --margin "0 2" "Aborted."
        exit 0
    fi

    echo ""
    gum style --bold --margin "0 2" "Removing system files..."

    # Stop and disable the service before removing it
    if systemctl --user is-active --quiet eye-guard.service; then
        systemctl --user stop eye-guard.service
        gum style --foreground 82 "✓ Service stopped"
    fi

    if systemctl --user is-enabled --quiet eye-guard.service; then
        systemctl --user disable eye-guard.service
        gum style --foreground 82 "✓ Service disabled"
    fi

    local removed_any=false

    _remove_file() {
        local path="$1"
        local label="$2"
        if [[ -e "$path" || -L "$path" ]]; then
            rm -f "$path"
            gum style --foreground 82 "✓ Removed $label"
            removed_any=true
        else
            gum style --faint "  $label not found, skipping"
        fi
    }

    _remove_file "$SERVICE_DEST"      "systemd service ($SERVICE_DEST)"
    _remove_file "$INSTALL_BIN"       "binary symlink ($INSTALL_BIN)"
    _remove_file "$INSTALL_LISTENER"  "listener symlink ($INSTALL_LISTENER)"

    # Remove the installed project directory
    if [[ -d "$INSTALL_DIR" ]]; then
        rm -rf "$INSTALL_DIR"
        gum style --foreground 82 "✓ Removed install directory ($INSTALL_DIR)"
        removed_any=true
    else
        gum style --faint "  Install directory not found, skipping"
    fi
}

# ─── Dispatch ─────────────────────────────────────────────────────────────────

usage() {
    cat <<EOF
Usage: install.sh [command]

Commands:
  install      Install Eye Guard CLI (default)
  uninstall    Remove system files installed by this script
  help         Show this message
EOF
}

require_gum

case "${1:-install}" in
    install)   cmd_install   ;;
    uninstall) cmd_uninstall ;;
    help|--help|-h) usage    ;;
    *)
        echo "Error: unknown command '$1'." >&2
        usage >&2
        exit 1
        ;;
esac
