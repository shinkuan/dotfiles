import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../../config"
import "../../services"
import "../../components"

// Live miniature of one window inside a cell; input lives in the overview's
// grid MouseArea so a drag survives the cell rebuild on activity switches.
Item {
    id: root

    required property var win          // { toplevel, address, title, cls, x, y, w, h }
    required property var overview     // OverviewWindow
    readonly property bool active: overview.active
    readonly property real scale: overview.previewScale
    readonly property bool lifted: overview.dragWin ? overview.dragWin.address === win.address : false

    // clamped to the cell so partly off-screen windows never spill into neighbours
    x: Math.max(0, Math.min(Math.round(win.x * scale), parent.width - width))
    y: Math.max(0, Math.min(Math.round(win.y * scale), parent.height - height))
    width: Math.max(12, Math.min(Math.round(win.w * scale), parent.width))
    height: Math.max(8, Math.min(Math.round(win.h * scale), parent.height))
    opacity: lifted ? 0.25 : 1

    // opaque backing: a translucent window's clear areas read as a flat
    // colour, never as whatever sits under the preview
    Rectangle {
        anchors.fill: parent
        radius: Theme.capsule ? 8 : Theme.outlined ? 0 : 4
        color: Colours.surfaceContainerLowest
        border.width: 1
        border.color: hover.hovered ? Theme.accent : Colours.alpha(Colours.outline, 0.6)
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
