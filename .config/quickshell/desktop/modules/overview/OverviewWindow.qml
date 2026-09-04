import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../config"
import "../../services"
import "../../components"

// Full-screen translucent layer on the focused monitor (the compositor blurs
// the desktop behind it) showing one activity's cell grid with live window
// previews drawn over it and a selection frame that glides between cells.
// The selection is the live workspace: arrows walk the grid and the desktop
// walks with them, Enter/Space keeps the cell and closes, Tab / letters change
// activity, Esc goes back to where the overview was opened. The pointer only
// clicks and drags — hovering never moves the selection.
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
    readonly property real translucency: 0.55   // layer and cells; the layer rule blurs behind them
    readonly property int headerH: 64
    readonly property real cellW: {
        const byWidth = (root.width - margin * 2 - gap * (KGrid.columns - 1)) / KGrid.columns;
        const byHeight = ((root.height - margin * 2 - headerH - gap * (KGrid.rows - 1)) / KGrid.rows) * logicalW / logicalH;
        return Math.floor(Math.min(byWidth, byHeight, 460));
    }
    readonly property real cellH: Math.round(cellW * logicalH / logicalW)
    readonly property real previewScale: cellW / logicalW
    readonly property alias content: content

    // toplevels of the shown activity, bottom to top; the one being dragged
    // and the one just moved stay in the list so their previews survive an
    // activity switch and glide to their new cell
    property list<var> shown: []
    property var dragWin: null    // WindowPreview under the pointer
    property var dropCell: null   // { x, y } under it while dragging
    property var moved: null

    visible: active
    WlrLayershell.namespace: "desktop-overview"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: Colours.alpha(Colours.surface, translucency)

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    onActiveChanged: {
        dragWin = null;
        dropCell = null;
        moved = null;
        if (active) {
            rebuild();
            keys.forceActiveFocus();
        }
    }

    // a workspace change while open (compositor shortcut) is followed: show
    // that activity and put the selection frame on the new cell
    onCurrentCellChanged: {
        if (!active || !currentCell)
            return;
        if (currentCell.activity !== Overview.activity)
            Overview.activity = currentCell.activity;
        Overview.selX = currentCell.x;
        Overview.selY = currentCell.y;
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
        const keep = [dragWin?.modelData ?? null, moved];
        const out = Hyprland.toplevels.values.filter(t => {
            if (keep.includes(t))
                return true;
            const ipc = t.lastIpcObject;
            const cell = KGrid.parse(t.workspace?.name ?? ipc?.workspace?.name ?? "");
            return cell && cell.activity === Overview.activity && ipc && !ipc.hidden && ipc.mapped;
        });
        // stacking: pinned above floating above tiled, then most recently focused last (on top)
        out.sort((a, b) => {
            const ia = a.lastIpcObject ?? {}, ib = b.lastIpcObject ?? {};
            if (!!ia.pinned !== !!ib.pinned)
                return ia.pinned ? 1 : -1;
            if (!!ia.floating !== !!ib.floating)
                return ia.floating ? 1 : -1;
            return (ib.focusHistoryID ?? 0) - (ia.focusHistoryID ?? 0);
        });
        shown = out;
    }

    // the move is already dispatched, so pull the new geometry at once and
    // again once Hyprland has settled: the preview's bindings come back at
    // 150 ms and should find the window where it ended up, not where it was
    function refreshSoon(): void {
        Overview.refresh();
        refreshLater.restart();
        forgetMoved.restart();
    }

    function focusWindow(win): void {
        if (win.cell)
            KGrid.switchTo(win.cell.activity, win.cell.x, win.cell.y);
        Hyprland.dispatch(`hl.dsp.focus({ window = "address:${win.address}" })`);
        Overview.hide();
    }

    Timer {
        id: refreshLater

        interval: 150
        onTriggered: Overview.refresh()
    }

    Timer {
        id: forgetMoved

        interval: 1500
        onTriggered: root.moved = null
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
        onClicked: Overview.cancel()
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
                            onClicked: Overview.setActivity(modelData.id)

                            DropArea {
                                anchors.fill: parent
                                onEntered: Overview.activity = parent.modelData.id
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: "↑↓←→ switch · Enter keep · Tab activity · drag windows between cells · Esc back"
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
                        }
                    }
                }

                // keyboard selection, which is also the live workspace: one
                // frame that glides between cells
                Rectangle {
                    x: (Overview.selX - 1) * (root.cellW + root.gap)
                    y: (Overview.selY - 1) * (root.cellH + root.gap)
                    z: 2000
                    width: root.cellW
                    height: root.cellH
                    radius: Theme.capsule ? 18 : Theme.outlined ? 0 : Theme.radiusItem
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.accent

                    Behavior on x {
                        enabled: root.active
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on y {
                        enabled: root.active
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                // previews over the whole grid, so a drag can cross cells
                Item {
                    anchors.fill: grid

                    Repeater {
                        model: ScriptModel {
                            values: root.shown
                        }

                        delegate: WindowPreview {
                            overview: root
                        }
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
                Overview.cancel();
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
                Overview.setActivity(id.id);
            }
            }
            event.accepted = true;
        }
    }
}
