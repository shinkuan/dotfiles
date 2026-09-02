# desktop shell

Self-built quickshell desktop: hidden bar with hover popouts, OSDs,
notification daemon, launcher, KGrid overview, region screenshot, polkit
agent and idle inhibitor. Run with `qs -c desktop` (normally via
`desktop-shell.service`).

## Layout

- `shell.qml` — root; one `Variants` over `Quickshell.screens`, so every
  window lives under it and follows monitor hotplug. Singletons with side
  effects are touched once in `Component.onCompleted` so they instantiate.
- `config/Config.qml` — appearance constants plus `config.json`, hot-loaded
  through a `JsonAdapter` (any key may be omitted; defaults live on the
  adapter). `config/Theme.qml` turns `appearance.style` into design tokens
  (panel material, radii, rim light / corner ticks / ruled rows, label face,
  accent, bar shape); components read `Theme`, never literal shapes.
  `components/Surface.qml` is the themed panel every popup is built on.
- `components/` — shared widgets: `StyledText`, `MaterialIcon`, `Clickable`,
  `IconButton`, `Toggle`, `Slider`, `ListItem`, `SectionLabel`, `Meter`,
  `Chip`.
- `services/` — singletons: `Colours` (hot-loads
  `$XDG_STATE_HOME/scheme/colours.json`), `Wallpaper`, `ShellState`
  (persisted toggles: bar pin, DND, keep awake, desktop clock), `Audio`
  (Pipewire), `Net` (Quickshell.Networking), `Vpn` (nmcli), `Brightness`
  (brightnessctl + ddcutil), `Resources`, `Session`, `KGrid` (reads the
  per-instance `kgrid.json` written by `kgrid.lua`), `Idle` (inhibitor on
  its own invisible surface), `Notifs`, `Launcher`, `Picker`, `Overview`,
  `Players` (Mpris), `Polkit`, `Requests` (global shortcuts + IPC).
- `modules/background/` — wallpaper layer + `DesktopClock`.
- `modules/frame/` — four 1×1 edge windows whose exclusive zones reserve
  the border ring (and the bar when pinned).
- `modules/shell/ShellSurface.qml` — full-screen top-layer window per
  monitor: bar, popouts, OSDs and notification popups. Its input mask is the
  left edge band plus whatever is expanded; everything else clicks through.
- `modules/bar/` — bar entries (`BarItem` marks hoverable entries with a
  `popout` id).
- `modules/popouts/` — `Popouts` container plus one file per popout.
- `modules/osd/`, `modules/notifications/`, `modules/launcher/`,
  `modules/areapicker/`, `modules/overview/`, `modules/polkit/` — the
  remaining windows.

## Hover model (read before touching input)

All hover decisions are made in `ShellSurface` by one `HoverHandler` and
geometry (`Bar.popoutAt`). Do **not** put a hover-enabled `MouseArea` under
anything that has a `HoverHandler`: in Qt 6 the handler steals the hover
and the `MouseArea` reports `exited`. Use `HoverHandler` for hover state and
plain `MouseArea` (no `hoverEnabled`) for clicks everywhere in the surface.

## Naming gotchas

- Colour roles `on*` are exposed as `*Text` (`Colours.surfaceText`): a
  property named `onFoo` is resolved as a signal-handler lookup inside JS
  expressions and reads as black.
- Singleton names must not collide with QML types (`State`, `Network`,
  `Settings` are all taken) — hence `ShellState`, `Net`.
- IPC function names must not collide with `qs ipc` subcommands (`show`,
  `call`, ...); use `open`/`close`/`pin`.
- `ColumnLayout.implicitWidth` is owned by the layout engine; popout roots
  set `width` explicitly.

## Adding a bar module

Create `modules/bar/Foo.qml` as a `BarItem { popout: "foo" }`, register it
in `modules/bar/qmldir`, add it to the `ColumnLayout` in `Bar.qml`.

## Adding a popout

Create `modules/popouts/FooPopout.qml` (a `ColumnLayout` with an explicit
`width`; set `readonly property bool needsKeyboard: true` while a text
field is focused), register it in `qmldir`, and add it to the `registry`
map plus a `Component` in `Popouts.qml`. Shortcut access: add a
`GlobalShortcut` in `services/Requests.qml` that emits `popout("foo")`.

## config.json

Hot-loaded; every key is optional.

| Key | Meaning |
|---|---|
| `appearance.style` | visual direction: `rim` (default), `ledger`, `capsule`, `signal`, `poster`, `classic` — tokens live in `config/Theme.qml` |
| `animation.scale` | multiplier for all animation durations |
| `border.thickness` / `border.rounding` | hover ring width; corner rounding of the bar |
| `bar.width`, `bar.pinThreshold`, `bar.showResources` | bar width; drag distance that pins it; CPU/memory meters entry |
| `popouts.showOnHover`, `popouts.width`, `popouts.listHeight` | hover reveal; popout width; max list height |
| `osd.hideDelay`, `kgrid.osd`, `kgrid.hideDelay` | OSD timings; KGrid overlay on/off |
| `desktopClock.position`, `desktopClock.margin` | `top-left` … `bottom-right` / `bottom-center` |
| `notifications.timeout`, `criticalTimeout`, `maxHistory`, `width` | popup timeouts (0 = never), history size, popup width |
| `idle.inhibitWhenAudio`, `idle.joystickHold` | inhibit while audio plays; seconds to hold after controller input |
| `launcher.maxResults`, `actionPrefix`, `calcPrefix`, `clipPrefix`, `emojiPrefix`, `emojiFile`, `fuzzy`, `showDangerous`, `actions` | launcher behaviour and the action list (`name`, `icon`, `description`, `command`, `dangerous`, `enabled`; `@scheme` / `@variant` / `@wallpaper` / `@config` are built-in commands) |
| `screenshot.directory` | relative to `$HOME` |
| `resources.interval` | background poll interval in ms |
| `brightness.external`, `brightness.step` | use ddcutil for external displays; key step in percent |

## IPC targets

`bar` (toggle/pin/unpin/isPinned), `desktopClock`, `audio`, `brightness`,
`idle` (toggle/enable/disable/isEnabled/isInhibited/activity), `notifs`
(clear/toggleDnd/dnd), `launcher` (toggle/open/close/search/clipboard),
`overview` (toggle/open/close), `popout` (open <id>/close), `screenshot`
(region/regionCopy/cancel/capture), `session` (lock/suspend/logout),
`media` (playPause/next/previous/stop), `wallpaper` (set/get).
Call with `qs -c desktop ipc call <target> <function> [args]`.
