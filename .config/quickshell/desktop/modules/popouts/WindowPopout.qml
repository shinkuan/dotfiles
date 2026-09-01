import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../config"
import "../../services"
import "../../components"

ColumnLayout {
    id: root

    readonly property HyprlandToplevel toplevel: Hyprland.activeToplevel ?? Hyprland.toplevels.values.find(t => t.activated) ?? Hyprland.toplevels.values.find(t => t.lastIpcObject?.focusHistoryID === 0) ?? null
    readonly property var ipc: toplevel?.lastIpcObject ?? null
    readonly property var cell: KGrid.parse(toplevel?.workspace?.name ?? "")

    width: Config.popouts.width
    spacing: 8

    function dispatch(cmd: string): void {
        if (toplevel)
            Hyprland.dispatch(cmd);
    }

    StyledText {
        visible: root.toplevel === null
        text: "No focused window"
        color: Colours.surfaceVariantText
    }

    Rectangle {
        visible: root.toplevel !== null
        Layout.fillWidth: true
        implicitHeight: {
            const w = root.ipc?.size?.[0] ?? 16, h = root.ipc?.size?.[1] ?? 9;
            return Math.round(Math.min(220, width * h / Math.max(1, w)));
        }
        radius: Config.radius
        color: Colours.surfaceContainerHighest
        clip: true

        ScreencopyView {
            anchors.fill: parent
            anchors.margins: 1
            captureSource: root.toplevel?.wayland ?? null
            live: true
            paintCursor: false
        }
    }

    StyledText {
        Layout.fillWidth: true
        text: root.toplevel?.title ?? ""
        font.weight: Font.DemiBold
        wrapMode: Text.Wrap
        maximumLineCount: 2
    }

    StyledText {
        Layout.fillWidth: true
        text: [root.ipc?.class, root.cell ? `${KGrid.labelFor(root.cell.activity)} · ${root.cell.x},${root.cell.y}` : root.toplevel?.workspace?.name, root.ipc?.floating ? "floating" : "", root.ipc?.fullscreen ? "fullscreen" : ""].filter(s => s).join("  ·  ")
        color: Colours.surfaceVariantText
        font.pixelSize: Config.fontSize - 1
    }

    RowLayout {
        visible: root.toplevel !== null
        Layout.fillWidth: true
        spacing: 6

        Chip {
            icon: "fullscreen"
            text: "Fullscreen"
            checked: (root.ipc?.fullscreen ?? 0) !== 0
            onClicked: root.dispatch(`hl.dsp.window.fullscreen({ mode = "fullscreen", window = "address:${root.toplevel.address}" })`)
        }

        Chip {
            icon: "picture_in_picture_alt"
            text: "Float"
            checked: root.ipc?.floating ?? false
            onClicked: root.dispatch(`hl.dsp.window.float({ action = "toggle", window = "address:${root.toplevel.address}" })`)
        }

        Chip {
            icon: "push_pin"
            text: "Pin"
            checked: root.ipc?.pinned ?? false
            onClicked: root.dispatch(`hl.dsp.window.pin({ window = "address:${root.toplevel.address}" })`)
        }

        Item {
            Layout.fillWidth: true
        }

        Chip {
            icon: "close"
            text: "Close"
            accent: Colours.error
            accentText: Colours.errorText
            onClicked: root.dispatch(`hl.dsp.window.close({ window = "address:${root.toplevel.address}" })`)
        }
    }
}
