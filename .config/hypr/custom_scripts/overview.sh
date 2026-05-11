#!/usr/bin/env bash

set -u

child_pid=""
running=true

cleanup() {
	running=false
	if [[ -n "$child_pid" ]] && kill -0 "$child_pid" 2>/dev/null; then
		kill "$child_pid" 2>/dev/null || true
		wait "$child_pid" 2>/dev/null || true
	fi
}

trap cleanup INT TERM

while $running; do
	qs -c overview &
	child_pid=$!
	wait "$child_pid"

	# Prevent tight respawn loops if the command exits immediately.
	sleep 0.5
done
