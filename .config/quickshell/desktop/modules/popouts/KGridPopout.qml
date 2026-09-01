import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../config"
import "../../services"
import "../../components"

// Activity chips + the cell grid of the selected activity. Clicking a cell
// switches to it; clicking a chip switches to that activity's last cell.
ColumnLayout {
    id: root

    required property HyprlandMonitor monitor
    readonly property var cell: KGrid.parse(monitor?.activeWorkspace?.name ?? "")
    property string selected: cell?.activity ?? (KGrid.activities[0]?.id ?? "")
    readonly property var occupancy: KGrid.occupancy(selected)

    width: Config.popouts.width
    spacing: 10

    onCellChanged: {
        if (cell)
            selected = cell.activity;
    }

    Flow {
        id: chips

        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: KGrid.activities

            Chip {
                required property var modelData

                text: modelData.label
                checked: root.selected === modelData.id
                accent: root.cell?.activity === modelData.id ? Colours.primary : Colours.secondaryContainer
                accentText: root.cell?.activity === modelData.id ? Colours.primaryText : Colours.secondaryContainerText
                onClicked: {
                    if (root.selected === modelData.id)
                        KGrid.switchActivity(modelData.id);
                    else
                        root.selected = modelData.id;
                }
            }
        }
    }

    Grid {
        Layout.alignment: Qt.AlignHCenter
        columns: KGrid.columns
        spacing: 6

        Repeater {
            model: KGrid.columns * KGrid.rows

            Clickable {
                required property int index
                readonly property int cx: index % KGrid.columns + 1
                readonly property int cy: Math.floor(index / KGrid.columns) + 1
                readonly property bool here: root.cell && root.cell.activity === root.selected && root.cell.x === cx && root.cell.y === cy
                readonly property int windows: root.occupancy[cx + "," + cy] ?? 0

                width: 52
                height: 40
                radius: Config.radius
                baseColor: here ? Colours.primary : windows > 0 ? Colours.surfaceContainerHighest : Colours.alpha(Colours.surfaceContainerHighest, 0.4)
                hoverColor: here ? Colours.mix(Colours.primary, Colours.primaryText, 0.1) : Colours.mix(Colours.surfaceContainerHighest, Colours.surfaceText, 0.1)
                onClicked: KGrid.switchTo(root.selected, cx, cy)

                StyledText {
                    anchors.centerIn: parent
                    text: parent.windows > 0 ? parent.windows : ""
                    color: parent.here ? Colours.primaryText : Colours.surfaceVariantText
                    font.pixelSize: Config.fontSize - 1
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    anchors.centerIn: parent
                    visible: parent.windows === 0
                    width: 6
                    height: 6
                    radius: 3
                    color: parent.here ? Colours.primaryText : Colours.alpha(Colours.surfaceVariantText, 0.4)
                }
            }
        }
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: root.cell ? `${KGrid.labelFor(root.cell.activity)} · ${root.cell.x},${root.cell.y}` : "Not on a grid cell"
        color: Colours.surfaceVariantText
        font.pixelSize: Config.fontSize - 1
    }
}
