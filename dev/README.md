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

Until the autostart switches to the new shell, a nested session still runs
the current shell. Its theming is NOT display-scoped: with no
`caelestia/cli.json` it falls back to defaults and applies themes globally,
including OSC colour sequences pushed to every `/dev/pts` — which restains
the outer session's already-open terminals. The launch script therefore
seeds a gitignored `.config/caelestia/cli.json` with every theme output
disabled. If stray theme dirs (btop, spicetify, discord clients, ...) do
appear in the worktree after a nested run, `git clean -fd .config` removes
them (the gitignored seeds survive). To fix restained outer terminals,
re-apply the live palette:
`for pt in /dev/pts/[0-9]*; do printf '%b' "$(cat ~/.cache/hellwal/sequences.txt)" > "$pt"; done`

### Testing the desktop shell inside a nested session

The nested execs skip both the old shell and the session-start lock (they
check for an inherited `WAYLAND_DISPLAY`), so start the shell under test
manually with the nested session's environment:

```sh
env WAYLAND_DISPLAY=<nested socket> HYPRLAND_INSTANCE_SIGNATURE=<nested sig> \
    XDG_CONFIG_HOME=<worktree>/.config \
    XDG_STATE_HOME=/tmp/$USER-<worktree name>-state \
    XDG_CACHE_HOME=/tmp/$USER-<worktree name>-cache \
    qs -c desktop
```

The same env prefix works for `qs -c desktop ipc call ...` and for
`grim` (screenshots of the nested output for visual checks).

## verify-scheme.sh

Acceptance / regression test for `.local/bin/scheme`: renders
`dynamic/content/dark` for the wallpaper in a throwaway XDG sandbox and
requires the result to be bit-for-bit identical to
`fixtures/scheme-baseline.json` (all 120 colour names). Run it after any
change to the colour generation pipeline.
