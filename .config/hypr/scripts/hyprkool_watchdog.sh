#!/usr/bin/env bash

# Kill any existing instances of this watchdog to prevent duplicates
for pid in $(pgrep -f "hyprkool_watchdog.sh"); do
    if [ "$pid" != "$$" ]; then
        kill -9 "$pid" 2>/dev/null
    fi
done

while true; do
    # Check if hyprkool daemon is running
    if ! pgrep -f "hyprkool daemon" >/dev/null; then
        hyprkool daemon &
    fi
    sleep 3
done
