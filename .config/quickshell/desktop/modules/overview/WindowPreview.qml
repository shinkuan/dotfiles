import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../../config"
import "../../services"
import Quickshell.Hyprland
import "../../components"

// Live miniature of one window, placed over the grid at its scaled on-screen
// position. It is its own drag source: pull it onto another cell (or an
// activity chip) to move the window; afterwards the position bindings come
// back and it glides to wherever Hyprland put it.
Item {
    id: root

    required property var modelData   // HyprlandToplevel
    required property int index
    required property var overview    // OverviewWindow

    readonly property var ipc: modelData.lastIpcObject
    readonly property string address: ipc?.address ?? ("0x" + modelData.address)
    readonly property string cls: ipc?.class ?? ""
    readonly property var cell: KGrid.parse(modelData.workspace?.name ?? ipc?.workspace?.name ?? "")
    readonly property var mon: modelData.monitor ?? overview.monitor
    readonly property real scale: overview.previewScale
    readonly property real relX: (ipc?.at?.[0] ?? 0) - (mon?.x ?? 0)
    readonly property real relY: (ipc?.at?.[1] ?? 0) - (mon?.y ?? 0)
    readonly property real targetW: Math.max(12, Math.min(Math.round((ipc?.size?.[0] ?? 100) * scale), overview.cellW))
    readonly property real targetH: Math.max(8, Math.min(Math.round((ipc?.size?.[1] ?? 100) * scale), overview.cellH))
    // clamped into the cell so a partly off-screen window never spills into a neighbour
    readonly property real initX: (cell ? (cell.x - 1) * (overview.cellW + overview.gap) : 0) + Math.max(0, Math.min(Math.round(relX * scale), overview.cellW - targetW))
    readonly property real initY: (cell ? (cell.y - 1) * (overview.cellH + overview.gap) : 0) + Math.max(0, Math.min(Math.round(relY * scale), overview.cellH - targetH))
    readonly property bool dragging: overview.dragWin === root
    readonly property bool compact: Math.min(targetW, targetH) < Config.fontSize * 4
    readonly property var entry: DesktopEntries.heuristicLookup(cls)
    readonly property string icon: Quickshell.iconPath(entry?.icon ?? cls, "application-x-executable")

    x: initX
    y: initY
    width: targetW
    height: targetH
    z: dragging ? 1000 : index
    Drag.active: input.drag.active

    Behavior on x {
        enabled: !root.dragging
        NumberAnimation {
            duration: Theme.spatialDuration
            easing.type: Theme.spatialType
            easing.bezierCurve: Theme.spatialCurve
        }
    }

    Behavior on y {
        enabled: !root.dragging
        NumberAnimation {
            duration: Theme.spatialDuration
            easing.type: Theme.spatialType
            easing.bezierCurve: Theme.spatialCurve
        }
    }

    Behavior on width {
        NumberAnimation {
            duration: Config.animDuration
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: Config.animDuration
        }
    }

    // dragging writes x/y directly, which breaks the bindings; put them back
    function settle(): void {
        x = Qt.binding(() => root.initX);
        y = Qt.binding(() => root.initY);
    }

    Timer {
        id: settleLater

        interval: 150
        onTriggered: root.settle()
    }

    Rectangle {
        id: frame

        anchors.fill: parent
        radius: Theme.capsule ? 8 : Theme.outlined ? 0 : 6
        color: input.pressed && !root.dragging ? Colours.alpha(Theme.accent, 0.2) : hover.hovered || root.dragging ? Colours.alpha(Colours.surfaceText, 0.08) : "transparent"
        border.width: 1
        border.color: hover.hovered || root.dragging ? Theme.accent : Colours.alpha(Colours.outline, 0.5)
        clip: true

        Behavior on color {
            ColorAnimation {
                duration: Config.animDurationFast
            }
        }

        // The capture keeps the window's aspect inside its own rect, so it is
        // laid out at that aspect — large enough to cover the frame — and
        // squeezed onto the frame by a scale. It therefore fills the frame at
        // every ratio: while a dropped window animates to the size Hyprland
        // gave it, the image stretches with the frame instead of sitting in it
        // as a mismatched inset.
        Item {
            id: fit

            readonly property real aspect: {
                const s = capture.sourceSize;
                if (s.height > 0)
                    return s.width / s.height;
                const g = root.ipc?.size;
                return g && g[1] > 0 ? g[0] / g[1] : 1;
            }

            x: 1
            y: 1
            width: Math.max(frame.width - 2, (frame.height - 2) * aspect)
            height: width / aspect

            // only ever shrinks, so the capture is never upscaled
            transform: Scale {
                xScale: fit.width > 0 ? (frame.width - 2) / fit.width : 1
                yScale: fit.height > 0 ? (frame.height - 2) / fit.height : 1
            }

            ScreencopyView {
                id: capture

                anchors.fill: parent
                captureSource: root.overview.active ? root.modelData.wayland : null
                live: root.overview.active
                paintCursor: false
            }

            // a whisper of blur takes the aliasing out of the shrunk capture
            MultiEffect {
                anchors.fill: capture
                source: capture
                blurEnabled: true
                blurMax: 1
                blur: 1
            }
        }

        IconImage {
            anchors.centerIn: parent
            implicitSize: Math.round(Math.min(root.targetW, root.targetH) * (root.compact ? 0.45 : 0.25))
            source: root.icon
            asynchronous: true
        }
    }

    HoverHandler {
        id: hover
    }

    MouseArea {
        id: input

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        drag.target: root
        drag.threshold: 6
        onPressed: m => {
            root.Drag.hotSpot.x = m.x;
            root.Drag.hotSpot.y = m.y;
        }
        drag.onActiveChanged: {
            if (input.drag.active)
                root.overview.dragWin = root;
        }
        onReleased: m => {
            const dragged = root.overview.dragWin === root;
            const target = root.overview.dropCell;
            root.overview.dragWin = null;
            root.overview.dropCell = null;
            if (dragged) {
                const c = root.cell;
                if (target && (!c || c.activity !== Overview.activity || c.x !== target.x || c.y !== target.y)) {
                    KGrid.moveWindow(root.address, Overview.activity, target.x, target.y);
                    root.overview.moved = root.modelData;
                    root.overview.refreshSoon();
                    settleLater.restart();
                } else {
                    root.settle();
                }
                return;
            }
            if (m.button === Qt.MiddleButton)
                Hyprland.dispatch(`hl.dsp.window.close({ window = "address:${root.address}" })`);
            else
                root.overview.focusWindow(root);
        }
        onCanceled: {
            if (root.overview.dragWin === root) {
                root.overview.dragWin = null;
                root.overview.dropCell = null;
            }
            root.settle();
        }
    }

    // title tooltip
    Rectangle {
        visible: hover.hovered && !root.overview.dragWin
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: 4
        width: Math.min(tip.implicitWidth + 16, 320)
        height: tip.implicitHeight + 8
        radius: 6
        color: Colours.alpha(Colours.inverseSurface, 0.95)

        StyledText {
            id: tip

            anchors.centerIn: parent
            width: Math.min(implicitWidth, 304)
            text: root.modelData.title || root.cls
            color: Colours.inverseSurfaceText
            font.pixelSize: Config.fontSize - 1
        }
    }
}
