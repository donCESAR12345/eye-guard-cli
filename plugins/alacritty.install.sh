#!/bin/bash

# Sidecar installer for the alacritty plugin.
# Usage: alacritty.install.sh <interactive>
# Outputs KEY=value lines to stdout for each config variable.
#
# Alacritty themes are .toml files inside ~/.config/alacritty/themes/.
# The plugin writes a current-theme.toml file with the active import,
# which the main alacritty.toml must include via:
#   import = ["~/.config/alacritty/current-theme.toml"]

INTERACTIVE="${1:-false}"
ALACRITTY_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/alacritty/alacritty.toml"
THEME_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/alacritty/current-theme.toml"

DEFAULT_DARK_THEME="gruvbox_dark"
DEFAULT_LIGHT_THEME="gruvbox_light"

if [[ "$INTERACTIVE" == "true" ]]; then
    gum style --faint --margin "0 4" \
        "Tip: themes are .toml files in ~/.config/alacritty/themes/. Theme name = filename without .toml." >&2

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

# Ensure alacritty.toml includes the theme file
if [[ -f "$ALACRITTY_CONFIG" ]]; then
    if ! grep -q "current-theme.toml" "$ALACRITTY_CONFIG"; then
        gum style --faint --margin "0 4" \
            "Adding current-theme.toml import to alacritty.toml..." >&2
        # Prepend the import at the top of the config
        echo -e "[general]\nimport = [\"~/.config/alacritty/current-theme.toml\"]\n$(cat "$ALACRITTY_CONFIG")" \
            > "$ALACRITTY_CONFIG"
    fi
fi

# Create the theme file with the dark theme as default
mkdir -p "$(dirname "$THEME_FILE")"
echo "import = [\"~/.config/alacritty/themes/${dark_theme:-$DEFAULT_DARK_THEME}.toml\"]" \
    > "$THEME_FILE"

echo "ALACRITTY_DARK_THEME=\"${dark_theme:-$DEFAULT_DARK_THEME}\""
echo "ALACRITTY_LIGHT_THEME=\"${light_theme:-$DEFAULT_LIGHT_THEME}\""
