import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import "../../config"
import "../../services"
import "../../components"

// Live miniature of one window inside a cell. Left click focuses, middle
// click closes, dragging beyond a few pixels hands the window to the cell
// under the pointer on release.
Item {
    id: root

    required property var win          // { toplevel, address, title, cls, x, y, w, h }
    required property var overview     // OverviewWindow
    property bool dragging: false
    readonly property bool active: overview.active
    readonly property real scale: overview.previewScale

    x: dragging ? dragX : Math.round(win.x * scale)
    y: dragging ? dragY : Math.round(win.y * scale)
    width: Math.max(12, Math.round(win.w * scale))
    height: Math.max(8, Math.round(win.h * scale))
    z: dragging ? 100 : 0

    property real dragX: 0
    property real dragY: 0

    Rectangle {
        anchors.fill: parent
        radius: 4
        color: Colours.surfaceContainerHighest
        border.width: 1
        border.color: hover.hovered ? Colours.primary : Colours.alpha(Colours.outline, 0.6)
        clip: true

        ScreencopyView {
            id: capture

            anchors.fill: parent
            anchors.margins: 1
            captureSource: root.active ? root.win.toplevel.wayland : null
            live: root.active
            paintCursor: false
        }

        IconImage {
            visible: !capture.hasContent
            anchors.centerIn: parent
            implicitSize: Math.min(parent.width, parent.height) * 0.4
            source: Quickshell.iconPath(root.win.cls, "application-x-executable")
            asynchronous: true
            opacity: 0.9
        }
    }

    HoverHandler {
        id: hover
    }

    MouseArea {
        property point pressPos
        property point offset

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onPressed: m => {
            pressPos = mapToItem(root.overview.content, m.x, m.y);
            offset = Qt.point(m.x, m.y);
        }
        onPositionChanged: m => {
            if (!pressed || !(m.buttons & Qt.LeftButton))
                return;
            const p = mapToItem(root.overview.content, m.x, m.y);
            if (!root.dragging && Math.hypot(p.x - pressPos.x, p.y - pressPos.y) > 6)
                root.dragging = true;
            if (root.dragging) {
                const local = root.parent.mapFromItem(root.overview.content, p.x - offset.x, p.y - offset.y);
                root.dragX = local.x;
                root.dragY = local.y;
            }
        }
        onReleased: m => {
            if (root.dragging) {
                root.dragging = false;
                const p = mapToItem(root.overview.content, m.x, m.y);
                root.overview.dropWindow(root.win, p.x, p.y);
            } else if (m.button === Qt.MiddleButton) {
                Hyprland.dispatch(`hl.dsp.window.close("address:${root.win.address}")`);
            } else {
                root.overview.focusWindow(root.win);
            }
        }
    }

    // title tooltip
    Rectangle {
        visible: hover.hovered && !root.dragging
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: 4
        width: Math.min(tip.implicitWidth + 16, 320)
        height: tip.implicitHeight + 8
        radius: 6
        color: Colours.alpha(Colours.inverseSurface, 0.95)
        z: 50

        StyledText {
            id: tip

            anchors.centerIn: parent
            width: Math.min(implicitWidth, 304)
            text: root.win.title || root.win.cls
            color: Colours.inverseSurfaceText
            font.pixelSize: Config.fontSize - 1
        }
    }
}
