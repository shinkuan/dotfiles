import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../config"
import "../../services"
import "../../components"

// Full-screen overlay on the focused monitor showing one activity's cell
// grid with live window previews. Keyboard: arrows select, Enter/Space go,
// Tab / letters change activity (also mid-drag), Esc closes.
PanelWindow {
    id: root

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
    readonly property bool active: Overview.open && (monitor?.focused ?? false)
    readonly property var currentCell: KGrid.parse(monitor?.activeWorkspace?.name ?? "")
    // the overlay spans the monitor, so its own size is the logical screen size (transform included)
    readonly property real logicalW: root.width > 0 ? root.width : (monitor ? monitor.width / monitor.scale : 1920)
    readonly property real logicalH: root.height > 0 ? root.height : (monitor ? monitor.height / monitor.scale : 1080)
    readonly property int gap: 10
    readonly property int margin: 48
    readonly property int headerH: 64
    readonly property real cellW: {
        const byWidth = (root.width - margin * 2 - gap * (KGrid.columns - 1)) / KGrid.columns;
        const byHeight = ((root.height - margin * 2 - headerH - gap * (KGrid.rows - 1)) / KGrid.rows) * logicalW / logicalH;
        return Math.floor(Math.min(byWidth, byHeight, 460));
    }
    readonly property real cellH: Math.round(cellW * logicalH / logicalW)
    readonly property real previewScale: cellW / logicalW
    readonly property alias content: content

    // windows of the shown activity, keyed "x,y"
    property var cells: ({})

    // drag state lives here, not in the previews, so switching activity
    // mid-drag (which rebuilds every cell) keeps the window on the pointer
    property var dragWin: null
    property real dragX: 0
    property real dragY: 0
    property point dragOffset: Qt.point(0, 0)
    property var dropCell: null   // { x, y } under the pointer while dragging

    visible: active
    WlrLayershell.namespace: "desktop-overview"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: Colours.alpha(Colours.surface, 0.97)

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    onActiveChanged: {
        dragWin = null;
        dropCell = null;
        if (active) {
            rebuild();
            keys.forceActiveFocus();
        }
    }

    Connections {
        target: Hyprland.toplevels

        function onValuesChanged(): void {
            if (root.active)
                root.rebuild();
        }
    }

    Connections {
        target: Overview

        function onActivityChanged(): void {
            if (root.active)
                root.rebuild();
        }
    }

    function rebuild(): void {
        const out = {};
        for (const t of Hyprland.toplevels.values) {
            const ipc = t.lastIpcObject;
            const wsName = t.workspace?.name ?? ipc?.workspace?.name ?? "";
            const cell = KGrid.parse(wsName);
            if (!cell || cell.activity !== Overview.activity || !ipc || ipc.hidden || !ipc.mapped)
                continue;
            const mon = t.monitor ?? root.monitor;
            const key = cell.x + "," + cell.y;
            if (!out[key])
                out[key] = [];
            out[key].push({
                toplevel: t,
                address: ipc.address ?? ("0x" + t.address),   // KGrid's Lua expects the 0x form
                title: t.title,
                cls: ipc.class ?? "",
                x: ipc.at[0] - (mon?.x ?? 0),
                y: ipc.at[1] - (mon?.y ?? 0),
                w: ipc.size[0],
                h: ipc.size[1],
                order: ipc.focusHistoryID ?? 0
            });
        }
        for (const k in out)
            out[k].sort((a, b) => b.order - a.order);
        cells = out;
    }

    // grid coordinates; null in the gaps and outside
    function cellAt(px: real, py: real): var {
        const cx = Math.floor(px / (cellW + gap)) + 1;
        const cy = Math.floor(py / (cellH + gap)) + 1;
        if (cx < 1 || cx > KGrid.columns || cy < 1 || cy > KGrid.rows || px < 0 || py < 0)
            return null;
        if (px - (cx - 1) * (cellW + gap) > cellW || py - (cy - 1) * (cellH + gap) > cellH)
            return null;
        return { x: cx, y: cy };
    }

    // same clamping as WindowPreview, in grid coordinates
    function previewRect(win, cell): var {
        const w = Math.max(12, Math.min(Math.round(win.w * previewScale), cellW));
        const h = Math.max(8, Math.min(Math.round(win.h * previewScale), cellH));
        const x = Math.max(0, Math.min(Math.round(win.x * previewScale), cellW - w));
        const y = Math.max(0, Math.min(Math.round(win.y * previewScale), cellH - h));
        return { x: (cell.x - 1) * (cellW + gap) + x, y: (cell.y - 1) * (cellH + gap) + y, w: w, h: h };
    }

    // topmost preview under a grid point (later entries are drawn on top)
    function winAt(px: real, py: real): var {
        const cell = cellAt(px, py);
        if (!cell)
            return null;
        const wins = cells[cell.x + "," + cell.y] ?? [];
        for (let i = wins.length - 1; i >= 0; i--) {
            const r = previewRect(wins[i], cell);
            if (px >= r.x && px < r.x + r.w && py >= r.y && py < r.y + r.h)
                return wins[i];
        }
        return null;
    }

    function chipAt(px: real, py: real): var {
        const p = chips.mapFromItem(gridBox, px, py);
        const c = chips.childAt(p.x, p.y);
        return c && c.modelData ? c.modelData.id : null;
    }

    function endDrag(px: real, py: real): void {
        const target = cellAt(px, py);
        const win = dragWin;
        dragWin = null;
        dropCell = null;
        if (!target || !win)
            return;
        KGrid.moveWindow(win.address, Overview.activity, target.x, target.y);
        refreshLater.restart();
    }

    function focusWindow(win): void {
        const cell = KGrid.parse(win.toplevel.workspace?.name ?? "");
        if (cell)
            KGrid.switchTo(cell.activity, cell.x, cell.y);
        Hyprland.dispatch(`hl.dsp.focus({ window = "address:${win.address}" })`);
        Overview.hide();
    }

    Timer {
        id: refreshLater

        interval: 150
        onTriggered: Overview.refresh()
    }

    // window geometry / workspace changes do not signal; poll while open
    Timer {
        running: root.active
        interval: 700
        repeat: true
        onTriggered: {
            Overview.refresh();
            root.rebuild();
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Overview.hide()
    }

    Item {
        id: content

        anchors.fill: parent

        ColumnLayout {
            anchors.centerIn: parent
            spacing: root.gap

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: root.headerH - root.gap
                spacing: 8

                RowLayout {
                    id: chips

                    spacing: 8

                    Repeater {
                        model: KGrid.activities

                        Chip {
                            required property var modelData

                            text: modelData.label
                            checked: Overview.activity === modelData.id
                            accent: root.currentCell?.activity === modelData.id ? Theme.accent : Colours.secondaryContainer
                            accentText: root.currentCell?.activity === modelData.id ? Theme.accentText : Colours.secondaryContainerText
                            onClicked: Overview.activity = modelData.id
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: "↑↓←→ select · Enter go · Tab activity · drag windows between cells · Esc"
                    color: Colours.alpha(Colours.surfaceText, 0.7)
                    font.pixelSize: Config.fontSize - 1
                }
            }

            Item {
                id: gridBox

                implicitWidth: grid.width
                implicitHeight: grid.height

                Grid {
                    id: grid

                    columns: KGrid.columns
                    spacing: root.gap

                    Repeater {
                        model: KGrid.columns * KGrid.rows

                        WorkspaceCell {
                            required property int index

                            cx: index % KGrid.columns + 1
                            cy: Math.floor(index / KGrid.columns) + 1
                            overview: root
                            windows: root.cells[cx + "," + cy] ?? []
                        }
                    }
                }

                // the window being dragged, drawn above every cell
                Item {
                    id: ghost

                    visible: !!root.dragWin
                    x: root.dragX - root.dragOffset.x
                    y: root.dragY - root.dragOffset.y
                    width: root.dragWin ? Math.max(12, Math.min(Math.round(root.dragWin.w * root.previewScale), root.cellW)) : 0
                    height: root.dragWin ? Math.max(8, Math.min(Math.round(root.dragWin.h * root.previewScale), root.cellH)) : 0
                    z: 100

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.capsule ? 8 : Theme.outlined ? 0 : 4
                        color: Colours.surfaceContainerLowest   // same opaque backing as the cell previews
                        border.width: 2
                        border.color: Theme.accent
                        clip: true

                        ScreencopyView {
                            anchors.fill: parent
                            anchors.margins: 2
                            captureSource: root.dragWin ? root.dragWin.toplevel.wayland : null
                            live: !!root.dragWin
                            paintCursor: false
                        }
                    }
                }

                // one input surface for the whole grid: click a cell to go
                // there, click a preview to focus it, middle-click to close,
                // drag a preview onto a cell (hover an activity chip to
                // change activity mid-drag) to move the window
                MouseArea {
                    id: gridInput

                    property var pressWin: null
                    property point pressPos: Qt.point(0, 0)

                    anchors.fill: parent
                    z: 101
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onPressed: m => {
                        pressPos = Qt.point(m.x, m.y);
                        pressWin = root.winAt(m.x, m.y);
                    }
                    onPositionChanged: m => {
                        if (!pressed || !(m.buttons & Qt.LeftButton))
                            return;
                        if (!root.dragWin) {
                            if (!pressWin || Math.hypot(m.x - pressPos.x, m.y - pressPos.y) <= 6)
                                return;
                            const cell = root.cellAt(pressPos.x, pressPos.y);
                            const r = root.previewRect(pressWin, cell ?? { x: 1, y: 1 });
                            root.dragOffset = Qt.point(pressPos.x - r.x, pressPos.y - r.y);
                            root.dragWin = pressWin;
                        }
                        root.dragX = m.x;
                        root.dragY = m.y;
                        root.dropCell = root.cellAt(m.x, m.y);
                        const chip = root.chipAt(m.x, m.y);
                        if (chip && chip !== Overview.activity)
                            Overview.activity = chip;
                    }
                    onReleased: m => {
                        const win = pressWin;
                        pressWin = null;
                        if (root.dragWin) {
                            root.endDrag(m.x, m.y);
                            return;
                        }
                        if (win) {
                            if (m.button === Qt.MiddleButton)
                                Hyprland.dispatch(`hl.dsp.window.close({ window = "address:${win.address}" })`);
                            else
                                root.focusWindow(win);
                            return;
                        }
                        const cell = root.cellAt(m.x, m.y);
                        if (cell) {
                            KGrid.switchTo(Overview.activity, cell.x, cell.y);
                            Overview.hide();
                        } else {
                            Overview.hide();
                        }
                    }
                    onCanceled: {
                        pressWin = null;
                        root.dragWin = null;
                        root.dropCell = null;
                    }
                }
            }
        }
    }

    Item {
        id: keys

        focus: true
        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Escape:
                Overview.hide();
                break;
            case Qt.Key_Left:
            case Qt.Key_H:
                Overview.moveSelection(-1, 0);
                break;
            case Qt.Key_Right:
            case Qt.Key_L:
                Overview.moveSelection(1, 0);
                break;
            case Qt.Key_Up:
            case Qt.Key_K:
                Overview.moveSelection(0, -1);
                break;
            case Qt.Key_Down:
            case Qt.Key_J:
                Overview.moveSelection(0, 1);
                break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
            case Qt.Key_Space:
                Overview.go();
                break;
            case Qt.Key_Tab:
                Overview.nextActivity(1);
                break;
            case Qt.Key_Backtab:
                Overview.nextActivity(-1);
                break;
            default: {
                const id = KGrid.activities.find(a => a.id.toLowerCase() === event.text.toLowerCase() && event.text !== "");
                if (!id)
                    return;
                Overview.activity = id.id;
            }
            }
            event.accepted = true;
        }
    }
}
