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
    readonly property var occupancy: cell ? KGrid.occupancy(cell.activity) : ({})

    popout: "kgrid"
    spacing: 3

    // wheel moves vertically through the grid
    WheelHandler {
        onWheel: e => {
            if (root.cell)
                KGrid.switchTo(root.cell.activity, root.cell.x, Math.max(1, Math.min(KGrid.rows, root.cell.y + (e.angleDelta.y < 0 ? 1 : -1))));
        }
    }

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.cell ? KGrid.labelFor(root.cell.activity) : (root.wsName || "?")
        color: Theme.accent
        font.family: Theme.fontLabel
        font.weight: Theme.ledger ? Font.Medium : Font.Bold
        font.capitalization: Theme.labelUpper && !Theme.ledger ? Font.AllUppercase : Font.MixedCase
        font.letterSpacing: Theme.rim ? 0.5 : Theme.signal ? 1 : 0
        font.pixelSize: Theme.labelUpper && !Theme.ledger ? Config.fontSize - 2 : Config.fontSize
        width: Math.min(implicitWidth, Theme.barWidth - 6)
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
                readonly property bool occupied: (root.occupancy[(index % KGrid.columns + 1) + "," + (Math.floor(index / KGrid.columns) + 1)] ?? 0) > 0

                width: 4
                height: 4
                radius: Theme.outlined ? 0 : 2
                color: here ? Theme.accent : occupied ? Colours.alpha(Colours.surfaceText, 0.7) : Colours.alpha(Colours.surfaceVariantText, 0.3)
            }
        }
    }
}
