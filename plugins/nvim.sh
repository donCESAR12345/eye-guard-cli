#!/bin/bash

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BASE_DIR/../core/utils.sh"

MODE="$1"

load_config

# Select theme and background based on mode
case "$MODE" in
    dark)
        THEME="$NVIM_DARK_THEME"
        BG="dark"
        ;;
    light)
        THEME="$NVIM_LIGHT_THEME"
        BG="light"
        ;;
    *)
        log "Error: unknown mode '$MODE'"
        exit 1
        ;;
esac

SOCKET_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

for socket in "$SOCKET_DIR"/nvim*; do
    [[ -S "$socket" ]] || continue

    # Probe the socket to confirm the instance is alive; clean up dead sockets
    if ! nvim --server "$socket" --remote-expr "1" > /dev/null 2>&1; then
        log "Removing dead socket $socket"
        rm -f "$socket"
        continue
    fi

    nvim --server "$socket" --remote-send \
        "<Esc>:set background=$BG<CR>:silent! colorscheme $THEME<CR>" &
done

wait
