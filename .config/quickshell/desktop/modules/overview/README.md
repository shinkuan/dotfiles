# modules/overview

Full-screen overlay showing one activity's KGrid cell grid with live window
previews. `services/Overview.qml` holds the state (open, shown activity,
keyboard selection) and the `overview` IPC target; `OverviewWindow.qml` is the
per-monitor window.

## How it is put together

- `WorkspaceCell` is one flat cell of the grid: a click switches to that
  workspace, its `DropArea` makes it a drop target while a preview is dragged
  (`overview.dropCell`), hovering moves the keyboard selection.
- `WindowPreview` is one window, drawn in a layer over the *whole* grid, not
  inside a cell. Its position comes from bindings on the toplevel's
  `lastIpcObject` (`at` / `size`, relative to the window's own monitor,
  scaled by `previewScale` and clamped into its cell), so a window that moves
  glides to its new place. The preview is its own drag source
  (`drag.target`); on release it asks KGrid to move the window, remembers it
  as `overview.moved` so it stays in the model until the next refresh, and
  restores the position bindings 150 ms later.
- The window list is a `ScriptModel` (`overview.shown`), rebuilt on toplevel
  changes, activity changes and a 700 ms poll while open. `ScriptModel`
  keeps delegates for values that stay in the list, which is what lets a
  drag survive an activity switch: the dragged toplevel is always kept, and
  hovering an activity chip (a `DropArea`) switches the shown activity.
- Captures are plain `ScreencopyView`s with a 1 px `MultiEffect` blur on
  top; no opaque backing, so a translucent window shows the cell colour
  through. The app icon sits centred on every preview.
- Stacking: pinned above floating above tiled, most recently focused on top.
