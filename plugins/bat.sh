#!/bin/bash

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BASE_DIR/../core/utils.sh"

MODE="$1"
CONFIG_FILE="$HOME/.config/bat/config"

load_config

# Select theme based on mode
case "$MODE" in
    dark)  TARGET_THEME="$BAT_DARK_THEME"  ;;
    light) TARGET_THEME="$BAT_LIGHT_THEME" ;;
    *)
        log "Error: unknown mode '$MODE'"
        exit 1
        ;;
esac

# Ensure config directory and file exist
mkdir -p "$(dirname "$CONFIG_FILE")"
touch "$CONFIG_FILE"

# Replace existing --theme line, or append it if absent
if grep -q "^--theme=" "$CONFIG_FILE"; then
    sed -i "s|^--theme=.*|--theme=\"$TARGET_THEME\"|" "$CONFIG_FILE"
else
    echo "--theme=\"$TARGET_THEME\"" >> "$CONFIG_FILE"
fi
