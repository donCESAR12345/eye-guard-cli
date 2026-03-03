#!/bin/bash

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BASE_DIR/../core/utils.sh"

MODE="$1"
CONFIG_FILE="$HOME/.config/zellij/config.kdl"

load_config

# Select theme based on mode
case "$MODE" in
    dark)  TARGET_THEME="$ZELLIJ_DARK_THEME"  ;;
    light) TARGET_THEME="$ZELLIJ_LIGHT_THEME" ;;
    *)
        log "Error: unknown mode '$MODE'"
        exit 1
        ;;
esac

if [[ ! -f "$CONFIG_FILE" ]]; then
    log "Error: Zellij config not found at $CONFIG_FILE"
    exit 1
fi

# Replace existing theme line, or append it if absent
if grep -q '^theme ' "$CONFIG_FILE"; then
    sed -i "s|^theme \".*\"|theme \"$TARGET_THEME\"|" "$CONFIG_FILE"
else
    echo "theme \"$TARGET_THEME\"" >> "$CONFIG_FILE"
fi
