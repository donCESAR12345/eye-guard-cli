#!/bin/bash

sync_zellij() {
    local mode=$1 # 1=Dark, 2=Light
    local config_file="$HOME/.config/zellij/config.kdl"

    # Pull theme names from config
    if [ "$mode" -eq 1 ]; then
        local target_theme="$ZELLIJ_DARK_THEME"
    else
        local target_theme="$ZELLIJ_LIGHT_THEME"
    fi

    # Check if config exists
    if [ ! -f "$config_file" ]; then
        echo "Error: Zellij config not found at $config_file"
        return 1
    fi

    # Replace theme config line
    sed -i "s/^theme \".*\"/theme \"$target_theme\"/" "$config_file"
}
