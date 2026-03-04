#!/bin/bash

INTERACTIVE="${1:-false}"
FOOT_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/foot/foot.ini"

if [[ "$INTERACTIVE" == "true" ]]; then
    config_path=$(gum input \
        --prompt "  foot config path: " \
        --placeholder "$FOOT_CONFIG" \
        --value "$FOOT_CONFIG") >&2
    FOOT_CONFIG="${config_path:-$FOOT_CONFIG}"
fi

if [[ ! -f "$FOOT_CONFIG" ]]; then
    gum style --foreground 196 --margin "0 4" \
        "Warning: foot config not found at $FOOT_CONFIG." \
        "Make sure [colors] and [colors2] blocks are defined before using this plugin." >&2
fi

# foot has no theme name vars — signal the dispatcher via a sentinel instead
echo "FOOT_ENABLED=\"true\""
echo "# foot: themes are defined as [colors] and [colors2] in $FOOT_CONFIG"
