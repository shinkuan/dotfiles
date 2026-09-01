# hypr

Hyprland is configured in Lua (`hyprland.lua` + `hyprland/*.lua`); there is
no `.conf` tree. `hyprlock.conf` and `hypridle.conf` are hyprlang files for
their own daemons.

## Layout

| File | Contents |
|---|---|
| `hyprland.lua` | entry point; seeds `scheme/current.lua` and requires the modules below |
| `hyprland/util.lua` | helpers; every path derives from `XDG_CONFIG_HOME` via `config_home()` / `hypr_dir()` |
| `hyprland/env.lua` | environment variables (XDG, NVIDIA, Qt, fcitx) |
| `hyprland/monitors.lua` | generic monitor fallback; real layouts go in `local.lua` |
| `hyprland/general.lua` | look & feel, layouts, input, animations (colours from `scheme.lua`) |
| `hyprland/scheme.lua` | loads the generated `scheme/current.lua` |
| `hyprland/kgrid.lua` | 2D workspace engine (see below) |
| `hyprland/keybinds.lua` | all binds |
| `hyprland/rules.lua` | window / layer rules |
| `hyprland/execs.lua` | autostart |
| `hyprland/rpm.lua` | plugin (Hypr-DarkWindow) setup |
| `hyprland/var.lua` | app commands used by binds |
| `hyprland/local.lua` | **gitignored** per-machine overrides (monitors, machine daemons); seeded from `local.lua.example` |
| `scheme/` | generated colour files (`current.lua`, `current.conf`; gitignored) |
| `custom_scripts/` | helpers called from binds |

## KGrid

Each activity (`main`, `Z`, `X`, ...) is a 5×5 grid of cells named
`activity:(x y)` whose numeric ids are a pure function of the position, so
slide directions survive reloads. `M.defs` in `kgrid.lua` holds `{ id, label }`
per activity; the label is what the shell shows. On load the module writes
`$XDG_RUNTIME_DIR/hypr/<instance>/kgrid.json` (grid size + activities), the
single source the desktop shell reads. Shell code calls into it with
`hyprctl dispatch '(function() KGrid.switch_name("Z:(2 3)") return hl.dsp.no_op() end)()'`.

To add an activity: append to `M.defs` and add the two binds
(`switch_activity(id)` / `switch_activity(id, true)`) in `keybinds.lua`.

## Binds and the desktop shell

Shell features are bound as global shortcuts (`dsp.global("desktop:<name>")`,
registered by the shell's `services/Requests.qml`). Actions that should keep
working without the shell use `qs -c desktop ipc call ... || <fallback tool>`.
Hyprland 0.56 dispatchers take Lua tables, e.g.
`hl.dsp.window.close({ window = "address:0x..." })`.

## Autostart

`execs.lua` imports the session environment into the systemd user manager and
restarts `desktop-shell`, `hypridle` and `joystick-idle-watch`. Inside a nested
session (inherited `WAYLAND_DISPLAY`) that block is skipped so the shell under
test can be started by hand and the session does not lock.

## Idle

`hypridle.conf`: 15 min lock (via `loginctl lock-session` → hyprlock), 30 min
DPMS off, lock before sleep. The shell's idle inhibitor (keep-awake toggle,
audio playback, controller input) stops these timers.
