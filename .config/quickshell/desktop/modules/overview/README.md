# modules/overview

Full-screen overlay showing one activity's KGrid cell grid with live window
previews. `services/Overview.qml` holds the state (open, shown activity,
selected cell, the cell it was opened on) and the `overview` IPC target;
`OverviewWindow.qml` is the per-monitor window.

The selection is not a preview of where you *could* go — it is the current
workspace. `show()` puts it on the cell the overview was opened from, every
`moveSelection` / `setActivity` calls `follow()`, which switches the compositor
to the selected cell unless it is already there, and `OverviewWindow`'s
`onCurrentCellChanged` syncs the selection back when the workspace changes for
any other reason. So Enter (`go()`) only has to close, and Esc (`cancel()`)
returns to `Overview.origin`. A drag preview assigns `Overview.activity`
directly instead of going through `setActivity`, so hovering an activity chip
mid-drag shows that activity without moving the desktop.

## How it is put together

- `WorkspaceCell` is one flat cell of the grid: a click selects it and goes
  there, its `DropArea` makes it a drop target while a preview is dragged
  (`overview.dropCell`). Nothing reacts to plain hovering — the pointer only
  clicks and drags.
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
- The capture fills its frame rather than fitting inside it: a
  `ScreencopyView` keeps the window's aspect within its own rect, so the pair
  sits in a `fit` Item laid out at that aspect (big enough to cover the
  frame) and a `Scale` transform squeezes it onto the frame — only ever
  shrinking, so nothing is upscaled. Ratios only differ while a dropped
  window animates to its new size, and there the image now stretches with
  the frame instead of floating inside it.
- Stacking: pinned above floating above tiled, most recently focused on top.
