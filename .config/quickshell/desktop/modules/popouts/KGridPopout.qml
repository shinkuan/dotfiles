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

    // One row, exactly as wide as the grid: the multi-letter label is a pill,
    // single letters are compact squares sized to fit.
    Row {
        id: chips

        readonly property int gridWidth: KGrid.columns * 52 + (KGrid.columns - 1) * 6
        readonly property int gap: 4
        readonly property int wideCount: KGrid.activities.filter(a => a.label.length > 1).length
        readonly property int wideWidth: 48
        readonly property int narrowCount: Math.max(1, KGrid.activities.length - wideCount)
        readonly property int narrowWidth: Math.max(18, Math.min(30, Math.floor((gridWidth - wideCount * wideWidth - gap * (KGrid.activities.length - 1)) / narrowCount)))

        Layout.alignment: Qt.AlignHCenter
        spacing: gap

        Repeater {
            model: KGrid.activities

            Clickable {
                id: chip

                required property var modelData
                readonly property bool current: root.cell?.activity === modelData.id
                readonly property bool selected: root.selected === modelData.id

                width: modelData.label.length > 1 ? chips.wideWidth : chips.narrowWidth
                height: 26
                radius: Config.radius
                baseColor: selected ? (current ? Theme.accent : Colours.secondaryContainer) : Colours.alpha(Colours.surfaceContainerHighest, 0.4)
                hoverColor: selected ? Colours.mix(baseColor, current ? Theme.accentText : Colours.secondaryContainerText, 0.1) : Colours.mix(Colours.surfaceContainerHighest, Colours.surfaceText, 0.1)
                onClicked: {
                    if (root.selected === modelData.id)
                        KGrid.switchActivity(modelData.id);
                    else
                        root.selected = modelData.id;
                }

                StyledText {
                    anchors.centerIn: parent
                    text: chip.modelData.label
                    color: chip.selected ? (chip.current ? Theme.accentText : Colours.secondaryContainerText) : Colours.surfaceVariantText
                    font.pixelSize: Config.fontSize - 2
                    font.weight: Font.DemiBold
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
                baseColor: here ? Theme.accent : windows > 0 ? Colours.surfaceContainerHighest : Colours.alpha(Colours.surfaceContainerHighest, 0.4)
                hoverColor: here ? Colours.mix(Theme.accent, Theme.accentText, 0.1) : Colours.mix(Colours.surfaceContainerHighest, Colours.surfaceText, 0.1)
                onClicked: KGrid.switchTo(root.selected, cx, cy)

                StyledText {
                    anchors.centerIn: parent
                    text: parent.windows > 0 ? parent.windows : ""
                    color: parent.here ? Theme.accentText : Colours.surfaceVariantText
                    font.pixelSize: Config.fontSize - 1
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    anchors.centerIn: parent
                    visible: parent.windows === 0
                    width: 6
                    height: 6
                    radius: 3
                    color: parent.here ? Theme.accentText : Colours.alpha(Colours.surfaceVariantText, 0.4)
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
