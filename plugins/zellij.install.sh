#!/bin/bash

# Sidecar installer for the zellij plugin.
# Usage: zellij.install.sh <interactive>
# Outputs KEY=value lines to stdout for each config variable.

INTERACTIVE="${1:-false}"

# gruvbox-dark and gruvbox-light ship built-in with Zellij.
DEFAULT_DARK_THEME="gruvbox-dark"
DEFAULT_LIGHT_THEME="gruvbox-light"

if [[ "$INTERACTIVE" == "true" ]]; then
    gum style --faint --margin "0 4" \
        "Tip: see https://zellij.dev/documentation/theme-list for all built-in themes." >&2

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

echo "ZELLIJ_DARK_THEME=\"${dark_theme:-$DEFAULT_DARK_THEME}\""
echo "ZELLIJ_LIGHT_THEME=\"${light_theme:-$DEFAULT_LIGHT_THEME}\""
