# desktop shell

Self-built quickshell desktop: hidden bar with hover reveal, wallpaper
background layer, and (coming) popouts, OSDs, notifications and launcher.
Run with `qs -c desktop`.

## Layout

- `shell.qml` — root; one `Variants` over `Quickshell.screens`, so every
  window must live under it to appear on all monitors and follow hotplug.
- `config/Config.qml` — appearance/behaviour constants.
- `services/` — singletons: `Colours` (hot-loads
  `$XDG_STATE_HOME/scheme/colours.json`), `Wallpaper` (follows
  `$XDG_STATE_HOME/wallpaper/path.txt`), `BarState` (pin state, persists
  across config reloads, IPC target `bar`: `toggle`/`pin`/`unpin`/`isPinned`).
- `modules/background/` — per-screen wallpaper layer.
- `modules/frame/` — four 1×1 edge windows whose exclusive zones reserve the
  border ring (and the bar when pinned); the main surface reserves nothing.
- `modules/shell/ShellSurface.qml` — full-screen top-layer window. Its input
  mask is the screen interior Xor'd away, leaving the border ring (plus the
  bar strip) interactive and everything else click-through. Hovering the
  left band reveals the bar; dragging inward pins it; a fullscreen window on
  the workspace disables the whole surface.
- `modules/bar/` — bar content: KGrid indicator, tray (menus via
  `QsMenuAnchor`), status icons, clock.

## Adding a bar module

Create `modules/bar/Foo.qml`, register it in `modules/bar/qmldir`, and add it
to the `ColumnLayout` in `Bar.qml`.

## Adding a service

Create `services/Foo.qml` with `pragma Singleton` + a `Singleton` root and
register it in `services/qmldir`.

## IPC naming

Avoid IPC function names that collide with `qs ipc` subcommands (`show`,
`call`, ...) — they get swallowed by the CLI before reaching the handler.
