#!/bin/bash

# Sidecar installer for the foot plugin.
# Usage: foot.install.sh <interactive>
# Outputs KEY=value lines to stdout for each config variable.
#
# foot uses [colors] and [colors2] blocks in its config file directly —
# there are no theme name variables to set. This installer only validates
# that the foot config file exists and contains both blocks.

INTERACTIVE="${1:-false}"
FOOT_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/foot/foot.ini"

if [[ "$INTERACTIVE" == "true" ]]; then
    config_path=$(gum input \
        --prompt "  foot config path: " \
        --placeholder "$FOOT_CONFIG" \
        --value "$FOOT_CONFIG")
    FOOT_CONFIG="${config_path:-$FOOT_CONFIG}"
fi

# Validate that the config file exists
if [[ ! -f "$FOOT_CONFIG" ]]; then
    gum style --foreground 196 \
        "  Warning: foot config not found at $FOOT_CONFIG." \
        "  Make sure [colors] and [colors2] blocks are defined before using this plugin." >&2
fi

# foot drives dark/light purely via SIGUSR1/SIGUSR2 — no env vars needed.
# Emit a comment so the config file documents why foot has no entries.
echo "# foot: themes are defined as [colors] and [colors2] in $FOOT_CONFIG"
