# modules/dashboard

The top-centre panel. `Dashboard.qml` owns the reveal (hover hotspot, `SUPER+G`,
IPC `dashboard`) and lays the tiles out on a 3 × 3 `GridLayout`:

```
InfoTile   | calendar (CalendarView in a DashTile) | EventsTile
InfoTile   | MediaTile                             | TodoTile
InfoTile   | UsageTile                             | TodoTile
```

Column widths and row heights are the `infoWidth` / `calendarWidth` /
`tallRow` / `shortRow` constants on `Dashboard.qml`; the panel height follows
from them and the width from `Config.dashboard.width`.

## Adding or changing a tile

- Every tile is a `DashTile`: a rounded `Rectangle` with `pad` and the
  `innerWidth` / `innerHeight` of its content area. Set `outerTL` … `outerBR`
  on the tiles that touch the panel's outer corners so those corners round
  with the panel in frame style; the rest stay tighter.
- Place it with `Layout.row` / `Layout.column` (and `rowSpan`) and give it
  either a preferred size from the constants or `fillWidth` / `fillHeight`.
- Register the file in `qmldir`.
- Data comes from the services: `Calendar` (events, tasks, `toggleTodo`,
  `addTodo`), `Notifs`, `Players`, `Resources`. A tile that polls something
  expensive should gate it on `Dashboard.shown` the way `UsageTile.active`
  bumps `Resources.watchers`.
- Section headings are `SectionLabel`; small counts are the accent pills in
  `InfoTile` / `TodoTile`. `Ring` draws the arc gauges.
