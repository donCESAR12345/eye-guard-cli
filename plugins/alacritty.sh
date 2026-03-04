#!/bin/bash

BASE_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$BASE_DIR/../core/utils.sh"

MODE="$1"
ALACRITTY_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/alacritty/alacritty.toml"
THEME_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/alacritty/current-theme.toml"

load_config

case "$MODE" in
    dark)  TARGET_THEME="$ALACRITTY_DARK_THEME"  ;;
    light) TARGET_THEME="$ALACRITTY_LIGHT_THEME" ;;
    *)
        log "Error: unknown mode '$MODE'"
        exit 1
        ;;
esac

# In alacritty.sh, replace the hard exit with config creation
if [[ ! -f "$ALACRITTY_CONFIG" ]]; then
    log "Alacritty config not found at $ALACRITTY_CONFIG, creating it"
    mkdir -p "$(dirname "$ALACRITTY_CONFIG")"
    printf '[general]\nimport = ["~/.config/alacritty/current-theme.toml"]\n' \
        > "$ALACRITTY_CONFIG"
fi

# Write the theme import file — Alacritty hot-reloads automatically
echo "import = [\"~/.config/alacritty/themes/${TARGET_THEME}.toml\"]" > "$THEME_FILE"
