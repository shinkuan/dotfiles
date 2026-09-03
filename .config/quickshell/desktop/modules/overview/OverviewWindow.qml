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
// Tab / letters change activity, Esc closes.
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
                address: t.address,
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

    function cellAt(px: real, py: real): var {
        const p = grid.mapFromItem(content, px, py);
        const cx = Math.floor(p.x / (cellW + gap)) + 1;
        const cy = Math.floor(p.y / (cellH + gap)) + 1;
        if (cx < 1 || cx > KGrid.columns || cy < 1 || cy > KGrid.rows)
            return null;
        return { x: cx, y: cy };
    }

    function dropWindow(win, px: real, py: real): void {
        const target = cellAt(px, py);
        if (!target)
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

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: "↑↓←→ select · Enter go · Tab activity · drag windows between cells · Esc"
                    color: Colours.alpha(Colours.surfaceText, 0.7)
                    font.pixelSize: Config.fontSize - 1
                }
            }

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
