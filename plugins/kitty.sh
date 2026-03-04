#!/bin/bash

BASE_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$BASE_DIR/../core/utils.sh"

MODE="$1"

load_config

KITTY_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/kitty/kitty.conf"

if [[ ! -f "$KITTY_CONFIG" ]]; then
    log "Kitty config not found at $KITTY_CONFIG, creating it"
    mkdir -p "$(dirname "$KITTY_CONFIG")"
    touch "$KITTY_CONFIG"
fi

case "$MODE" in
    dark)  TARGET_THEME="$KITTY_DARK_THEME"  ;;
    light) TARGET_THEME="$KITTY_LIGHT_THEME" ;;
    *)
        log "Error: unknown mode '$MODE'"
        exit 1
        ;;
esac

# kitty +kitten themes applies the theme and hot-reloads all running instances
kitty +kitten themes --reload-in=all "$TARGET_THEME"
