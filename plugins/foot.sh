#!/bin/bash

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BASE_DIR/../core/utils.sh"

MODE="$1"

load_config

# foot reloads its config on SIGUSR1 (reads [colors]) and switches
# to the alternate palette on SIGUSR2 (reads [colors2]).
case "$MODE" in
    dark)  killall -USR1 foot 2>/dev/null ;;
    light) killall -USR2 foot 2>/dev/null ;;
    *)
        log "Error: unknown mode '$MODE'"
        exit 1
        ;;
esac
