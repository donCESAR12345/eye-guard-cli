#!/bin/bash

INTERACTIVE="${1:-false}"
GHOSTTY_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config"

DEFAULT_DARK_THEME="Gruvbox Dark"
DEFAULT_LIGHT_THEME="Gruvbox Light"

if [[ "$INTERACTIVE" == "true" ]]; then
    gum style --faint --margin "0 4" \
        "Tip: run 'ghostty +list-themes' to see all available built-in themes." >&2

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

dark_theme="${dark_theme:-$DEFAULT_DARK_THEME}"
light_theme="${light_theme:-$DEFAULT_LIGHT_THEME}"

# Write the combined theme line into ghostty's config now, at install time.
# The runtime plugin only needs to send a reload signal after this.
if [[ -f "$GHOSTTY_CONFIG" ]]; then
    if grep -q "^theme = " "$GHOSTTY_CONFIG"; then
        sed -i "s|^theme = .*|theme = light:\"$light_theme\",dark:\"$dark_theme\"|" \
            "$GHOSTTY_CONFIG"
    else
        echo "theme = light:\"$light_theme\",dark:\"$dark_theme\"" >> "$GHOSTTY_CONFIG"
    fi
    gum style --faint --margin "0 4" "Theme line written to $GHOSTTY_CONFIG" >&2
else
    gum style --foreground 196 --margin "0 4" \
        "Warning: Ghostty config not found at $GHOSTTY_CONFIG. Create it first." >&2
fi

echo "GHOSTTY_DARK_THEME=\"$dark_theme\""
echo "GHOSTTY_LIGHT_THEME=\"$light_theme\""
