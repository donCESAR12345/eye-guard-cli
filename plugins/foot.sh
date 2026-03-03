#!/bin/bash

sync_foot() {
    local mode=$1 # 1=Dark, 2=Light

    if [ "$mode" -eq 1 ]; then
        # Switch to [colors]
        killall -USR1 foot 2>/dev/null
    else
        # Switch to [colors2]
        killall -USR2 foot 2>/dev/null
    fi
}
