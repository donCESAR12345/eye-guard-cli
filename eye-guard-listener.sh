#!/bin/bash

BASE_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

source "$BASE_DIR/core/utils.sh"

# D-Bus org.freedesktop.appearance colour-scheme values:
#   0 = no preference, 1 = dark, 2 = light

LAST_MODE=""

log "Listener started, waiting for theme changes"

dbus-monitor --session \
    "type='signal',interface='org.freedesktop.portal.Settings',member='SettingChanged'" |
while read -r line; do

    # Wait for the org.freedesktop.appearance namespace
    if [[ "$line" != *"string \"org.freedesktop.appearance\""* ]]; then
        continue
    fi

    read -r key_line
    # Only act on the color-scheme key
    if [[ "$key_line" != *"string \"color-scheme\""* ]]; then
        continue
    fi

    read -r value_line
    # Extract the trailing digit (0, 1, or 2)
    raw_value=$(echo "$value_line" | grep -o '[0-9]$')

    # Translate D-Bus numeric value to a named mode at the boundary
    case "$raw_value" in
        1) mode="dark"  ;;
        2) mode="light" ;;
        *) continue     ;;  # 0 = no preference; ignore
    esac

    # Debounce: skip if the mode has not changed since the last signal
    if [[ "$mode" == "$LAST_MODE" ]]; then
        continue
    fi

    log "Detected switch to $mode mode"
    "$BASE_DIR/eye-guard-cli" set "$mode"
    LAST_MODE="$mode"

done
