#!/bin/bash

# ─── Paths ────────────────────────────────────────────────────────────────────

CACHE_DIR="$HOME/.cache/eye-guard-cli"
CACHE_FILE="$CACHE_DIR/current_mode"
EYE_GUARD_CONFIG="$HOME/.config/eye-guard-cli/config.env"

# ─── Logging ──────────────────────────────────────────────────────────────────

# log MESSAGE
# Prints a timestamped line to stdout.
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] eye-guard-cli: $*"
}

# ─── State ────────────────────────────────────────────────────────────────────

# update_state MODE
# Persists the current mode ("dark" or "light") to the cache file.
update_state() {
    local mode="$1"
    mkdir -p "$CACHE_DIR"
    echo "$mode" > "$CACHE_FILE"
}

# get_state
# Prints the last known mode, or "unknown" if no state has been saved yet.
get_state() {
    if [[ -f "$CACHE_FILE" ]]; then
        cat "$CACHE_FILE"
    else
        echo "unknown"
    fi
}

# ─── Config ───────────────────────────────────────────────────────────────────

# load_config
# Sources the user config file, or exits with an error if it is missing.
load_config() {
    if [[ -f "$EYE_GUARD_CONFIG" ]]; then
        source "$EYE_GUARD_CONFIG"
    else
        log "Error: config file not found at $EYE_GUARD_CONFIG. Run install.sh first."
        exit 1
    fi
}
