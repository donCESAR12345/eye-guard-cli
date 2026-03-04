#!/bin/bash

BASE_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$BASE_DIR/../core/utils.sh"

MODE="$1"
GHOSTTY_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config"

load_config

case "$MODE" in
    dark|light) ;;
    *)
        log "Error: unknown mode '$MODE'"
        exit 1
        ;;
esac

if [[ ! -f "$GHOSTTY_CONFIG" ]]; then
    log "Error: Ghostty config not found at $GHOSTTY_CONFIG"
    exit 1
fi

# Ghostty handles dark/light natively via theme = light:X,dark:Y in its config.
# We just need to trigger a reload so it re-evaluates the system appearance.
if systemctl --user is-active --quiet app-com.mitchellh.ghostty.service; then
    systemctl --user reload app-com.mitchellh.ghostty.service
else
    killall -SIGUSR2 ghostty 2>/dev/null
fi
