#!/bin/bash

# Sidecar installer for the nvim plugin.
# Usage: nvim.install.sh <interactive>
# Outputs KEY=value lines to stdout for each config variable.

INTERACTIVE="${1:-false}"

# habamax and morning ship with Neovim itself — no plugins required.
DEFAULT_DARK_THEME="habamax"
DEFAULT_LIGHT_THEME="morning"

if [[ "$INTERACTIVE" == "true" ]]; then
    gum style --faint --margin "0 4" \
        "Tip: run ':colorscheme <Tab>' inside Neovim to browse available themes." >&2

    dark_theme=$(gum input \
        --prompt "  Dark colorscheme: " \
        --placeholder "$DEFAULT_DARK_THEME" \
        --value "$DEFAULT_DARK_THEME")

    light_theme=$(gum input \
        --prompt "  Light colorscheme: " \
        --placeholder "$DEFAULT_LIGHT_THEME" \
        --value "$DEFAULT_LIGHT_THEME")
else
    dark_theme="$DEFAULT_DARK_THEME"
    light_theme="$DEFAULT_LIGHT_THEME"
fi

echo "NVIM_DARK_THEME=\"${dark_theme:-$DEFAULT_DARK_THEME}\""
echo "NVIM_LIGHT_THEME=\"${light_theme:-$DEFAULT_LIGHT_THEME}\""
