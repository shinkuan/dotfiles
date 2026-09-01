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

### Testing the desktop shell inside a nested session

The nested execs skip the systemd-managed shell and the session-start lock
(they check for an inherited `WAYLAND_DISPLAY`), so start the shell under
test manually with the nested session's environment. `.local/bin` of the
worktree must be on `PATH` for the `scheme` / `wallpaper` tools:

```sh
env WAYLAND_DISPLAY=<nested socket> HYPRLAND_INSTANCE_SIGNATURE=<nested sig> \
    XDG_CONFIG_HOME=<worktree>/.config \
    XDG_STATE_HOME=/tmp/$USER-<worktree name>-state \
    XDG_CACHE_HOME=/tmp/$USER-<worktree name>-cache \
    PATH=<worktree>/.local/bin:$PATH \
    qs -c desktop
```

The same env prefix works for `qs -c desktop ipc call ...` and for `grim`
(screenshots of the nested output for visual checks — remember the prefix,
otherwise grim captures the live session).

- **Hover without a mouse**: `hyprctl -i <sig> dispatch 'hl.dsp.cursor.move({ x = 5, y = 600 })'`
  warps the nested cursor. A warp only produces a pointer enter/leave, not
  motion, so to "hover" a bar item warp out of the surface first, then onto
  the item at the screen's left edge (x ≤ border thickness).
- **Notifications and the tray** live on the D-Bus session bus, which the
  live shell already owns. To test the notification server start the shell
  on a private bus: `eval "$(dbus-launch --sh-syntax)"` in the same env,
  then `notify-send` from that environment. The tray is empty there.
- **Overview / area picker** need windows: spawn some with
  `hyprctl -i <sig> dispatch 'hl.dsp.exec_cmd("foot")'`.
- Everything the shell writes goes to the throwaway state/cache dirs; apps
  started inside the nested session may still drop config dirs into the
  worktree's `.config` (they are gitignored).

Until the live session runs the new shell, its `hyprlock` is the outer
session's business: a nested `hyprlock` that gets killed leaves Hyprland's
"lockscreen died" guard up, cleared with
`hyprctl -i <sig> eval 'hl.clear_crashed_lockscreen()'`.

## verify-scheme.sh

Acceptance / regression test for `.local/bin/scheme`: renders
`dynamic/content/dark` for the wallpaper in a throwaway XDG sandbox and
requires the result to be bit-for-bit identical to
`fixtures/scheme-baseline.json` (all 120 colour names). Run it after any
change to the colour generation pipeline.
