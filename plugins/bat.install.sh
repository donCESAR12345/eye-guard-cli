#!/bin/bash

# Sidecar installer for the bat plugin.
# Usage: bat.install.sh <interactive>
# Outputs KEY=value lines to stdout for each config variable.

INTERACTIVE="${1:-false}"

DEFAULT_DARK_THEME="Monokai Extended"
DEFAULT_LIGHT_THEME="Monokai Extended Light"

if [[ "$INTERACTIVE" == "true" ]]; then
    gum style --faint --margin "0 4" \
        "Tip: run 'bat --list-themes' to see all available themes." >&2

    dark_theme=$(gum input \
        --prompt "  Dark theme: " \
        --placeholder "$DEFAULT_DARK_THEME" \
        --value "$DEFAULT_DARK_THEME")

    light_theme=$(gum input \
        --prompt "  Light theme: " \
        --placeholder "$DEFAULT_LIGHT_THEME" \
        --value "$DEFAULT_LIGHT_THEME")
else
    dark_theme="$DEFAULT_DARK_THEME"
    light_theme="$DEFAULT_LIGHT_THEME"
fi

echo "BAT_DARK_THEME=\"${dark_theme:-$DEFAULT_DARK_THEME}\""
echo "BAT_LIGHT_THEME=\"${light_theme:-$DEFAULT_LIGHT_THEME}\""
