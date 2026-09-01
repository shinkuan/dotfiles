# dev/

Developer tooling for working on this repo from a worktree. Nothing in here
is installed to the target machine.

## nested-session.sh

Launches a nested Hyprland session running this worktree's config, isolated
from the live session:

- `XDG_CONFIG_HOME` points at this worktree's `.config`, so every
  XDG-compliant consumer (hypr, quickshell, foot, gtk, fastfetch, ...) reads
  the worktree copy instead of the live config.
- `XDG_STATE_HOME` / `XDG_CACHE_HOME` point at throwaway dirs under `/tmp`,
  so generated state (scheme output, cliphist db, shell persistence) never
  touches the live environment.
- Hyprland is started through `start-hyprland` (the watchdog wrapper shipped
  with the hyprland package), never directly.

Usage, from a terminal inside the live session:

```sh
dev/nested-session.sh            # plain
dev/nested-session.sh -- <args>  # extra args are passed to Hyprland
```

Interacting with the nested window: the outer session must pass shortcuts
through — toggle the outer escape submap (`SUPER+F12`, defined in the outer
session's per-machine config) before typing into the nested session, and
toggle it again after leaving. The nested config itself needs no escape key.

Multi-monitor hotplug can be tested from inside the nested session with
`hyprctl output create headless`.

## verify-scheme.sh

Acceptance / regression test for `.local/bin/scheme`: renders
`dynamic/content/dark` for the wallpaper in a throwaway XDG sandbox and
requires the result to be bit-for-bit identical to
`fixtures/scheme-baseline.json` (all 120 colour names). Run it after any
change to the colour generation pipeline.
