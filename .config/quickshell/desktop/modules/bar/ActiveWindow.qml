import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import "../../config"
import "../../services"
import "../../components"

// Focused window's icon; hover shows a live preview and window actions.
BarItem {
    id: root

    // activeToplevel is only tracked from events; fall back to the activated toplevel
    readonly property HyprlandToplevel toplevel: Hyprland.activeToplevel ?? Hyprland.toplevels.values.find(t => t.activated) ?? Hyprland.toplevels.values.find(t => t.lastIpcObject?.focusHistoryID === 0) ?? null
    readonly property string cls: toplevel?.lastIpcObject?.class ?? ""
    readonly property string iconSource: cls ? Quickshell.iconPath(DesktopEntries.heuristicLookup(cls)?.icon ?? cls, true) : ""

    popout: "window"
    visible: toplevel !== null

    Item {
        width: Config.iconSize + 2
        height: Config.iconSize + 2

        IconImage {
            anchors.fill: parent
            visible: root.iconSource !== ""
            source: root.iconSource
            asynchronous: true
        }

        MaterialIcon {
            anchors.centerIn: parent
            visible: root.iconSource === ""
            text: "web_asset"
            color: root.filled ? root.fgDim : Colours.surfaceVariantText
        }
    }

    onClicked: m => {
        if (m.button === Qt.MiddleButton && root.toplevel)
            Hyprland.dispatch(`hl.dsp.window.close({ window = "address:${root.toplevel.address}" })`);
    }
}
