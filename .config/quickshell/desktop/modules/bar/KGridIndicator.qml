import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../config"
import "../../services"

// Shows the current KGrid activity and cell, parsed from the workspace name
// ("activity:(x y)"); falls back to the raw name for plain workspaces.
ColumnLayout {
    id: root

    required property HyprlandMonitor monitor

    readonly property string wsName: monitor?.activeWorkspace?.name ?? ""
    readonly property var parsed: wsName.match(/^(.+):\((\d+) (\d+)\)$/)

    spacing: 2

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: {
            const activity = root.parsed?.[1] ?? root.wsName;
            return activity === "default" ? "main" : activity;
        }
        color: Colours.primary
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSize
        font.bold: true
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        visible: root.parsed !== null
        text: root.parsed ? `${root.parsed[2]},${root.parsed[3]}` : ""
        color: Colours.onSurfaceVariant
        font.family: Config.fontFamilyMono
        font.pixelSize: Config.fontSize - 3
    }
}
