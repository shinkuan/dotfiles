#!/usr/bin/env bash
# Acceptance test for the scheme tool (see dev/fixtures/scheme-baseline.json):
# for the same wallpaper, dynamic/content/dark must reproduce the baseline
# palette bit-for-bit — all 120 names, zero mismatches.
#
# Runs fully sandboxed (XDG dirs under mktemp), so it never touches live
# config or state.
set -euo pipefail

REPO_ROOT="$(realpath "$(dirname "$(realpath "$0")")/..")"
BASELINE="$REPO_ROOT/dev/fixtures/scheme-baseline.json"
WALL="${1:-$HOME/Pictures/Wallpapers/wlop_1.jpg}"

SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_CONFIG_HOME="$SANDBOX/config"
export XDG_STATE_HOME="$SANDBOX/state"
export XDG_CACHE_HOME="$SANDBOX/cache"

mkdir -p "$XDG_STATE_HOME/wallpaper"
printf '%s' "$WALL" > "$XDG_STATE_HOME/wallpaper/path.txt"

"$REPO_ROOT/.local/bin/scheme" set --name dynamic --variant content --mode dark >/dev/null

python3 - "$BASELINE" "$XDG_STATE_HOME/scheme/colours.json" <<'EOF'
import json, sys
base = json.load(open(sys.argv[1]))["colours"]
ours = json.load(open(sys.argv[2]))["colours"]
missing = sorted(set(base) - set(ours))
diff = [(k, base[k], ours[k]) for k in base if k in ours and base[k].lower() != ours[k].lower()]
for k in missing:
    print(f"MISSING {k}")
for k, want, got in diff:
    print(f"MISMATCH {k}: baseline={want} ours={got}")
if missing or diff:
    print(f"FAIL ({len(missing)} missing, {len(diff)} mismatched of {len(base)})")
    sys.exit(1)
print(f"PASS: {len(base)}/{len(base)} colours identical to baseline")
EOF
