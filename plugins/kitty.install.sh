#!/bin/bash

# Sidecar installer for the kitty plugin.
# Usage: kitty.install.sh <interactive>
# Outputs KEY=value lines to stdout for each config variable.

INTERACTIVE="${1:-false}"

# Both ship with kitty-themes out of the box
DEFAULT_DARK_THEME="Gruvbox Dark"
DEFAULT_LIGHT_THEME="Gruvbox Light"

if [[ "$INTERACTIVE" == "true" ]]; then
    gum style --faint --margin "0 4" \
        "Tip: run 'kitty +kitten themes' interactively to browse all available themes." >&2

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

echo "KITTY_DARK_THEME=\"${dark_theme:-$DEFAULT_DARK_THEME}\""
echo "KITTY_LIGHT_THEME=\"${light_theme:-$DEFAULT_LIGHT_THEME}\""
