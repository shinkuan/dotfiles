import QtQuick
import Quickshell.Hyprland
import "../../config"
import "../../services"
import "../../components"

// Current activity label and cell; hover shows the full grid.
BarItem {
    id: root

    required property HyprlandMonitor monitor
    readonly property string wsName: monitor?.activeWorkspace?.name ?? ""
    readonly property var cell: KGrid.parse(wsName)

    popout: "kgrid"
    spacing: 3

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.cell ? KGrid.labelFor(root.cell.activity) : (root.wsName || "?")
        color: Colours.primary
        font.weight: Font.Bold
        width: Math.min(implicitWidth, root.width - 4)
        horizontalAlignment: Text.AlignHCenter
    }

    Grid {
        anchors.horizontalCenter: parent.horizontalCenter
        columns: KGrid.columns
        spacing: 2
        visible: root.cell !== null

        Repeater {
            model: KGrid.columns * KGrid.rows

            Rectangle {
                required property int index
                readonly property bool here: root.cell && root.cell.x === index % KGrid.columns + 1 && root.cell.y === Math.floor(index / KGrid.columns) + 1

                width: 4
                height: 4
                radius: 2
                color: here ? Colours.primary : Colours.alpha(Colours.surfaceVariantText, 0.35)
            }
        }
    }
}
