import QtQuick
import Quickshell.Hyprland
import "../../config"
import "../../services"
import "../../components"

// Activity label + cell grid, shown briefly when this monitor changes cell.
// Silent while the overview is up: walking its grid changes the cell on every
// key, and it already draws the same thing much bigger.
Item {
    id: root

    required property HyprlandMonitor monitor

    readonly property string wsName: monitor?.activeWorkspace?.name ?? ""
    property var cell: null
    property var occupancy: ({})
    property bool shown: false
    property bool ready: false
    readonly property int dot: 14
    readonly property int gap: 10

    onWsNameChanged: {
        const c = KGrid.parse(wsName);
        if (!c || !ready || !Config.kgrid.osd || Overview.open)
            return;
        cell = c;
        occupancy = KGrid.occupancy(c.activity);
        shown = true;
        hide.restart();
    }

    Timer {
        interval: 1000
        running: true
        onTriggered: root.ready = true
    }

    Timer {
        id: hide

        interval: Config.kgrid.hideDelay
        onTriggered: root.shown = false
    }

    anchors.centerIn: parent
    width: panel.width
    height: panel.height
    opacity: shown ? 1 : 0
    scale: shown ? 1 : 0.9
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation {
            duration: Config.animDurationFast
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutCubic
        }
    }

    Surface {
        id: panel

        width: column.implicitWidth + 48
        height: column.implicitHeight + 36

        Column {
            id: column

            anchors.centerIn: parent
            spacing: 14

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.cell ? KGrid.labelFor(root.cell.activity) : ""
                color: Theme.accent
                font.family: Theme.fontLabel
                font.pixelSize: Theme.labelUpper ? Config.fontSize + 5 : Config.fontSize + 9
                font.weight: Font.Bold
                font.capitalization: Theme.labelUpper ? Font.AllUppercase : Font.MixedCase
                font.letterSpacing: Theme.labelUpper ? Theme.labelSpacing * 2 : 0
            }

            Grid {
                anchors.horizontalCenter: parent.horizontalCenter
                columns: KGrid.columns
                spacing: root.gap

                Repeater {
                    model: KGrid.columns * KGrid.rows

                    Rectangle {
                        required property int index
                        readonly property int cx: index % KGrid.columns + 1
                        readonly property int cy: Math.floor(index / KGrid.columns) + 1
                        readonly property bool here: root.cell && root.cell.x === cx && root.cell.y === cy
                        readonly property bool occupied: (root.occupancy[cx + "," + cy] ?? 0) > 0

                        width: root.dot
                        height: root.dot
                        radius: Theme.outlined ? 0 : root.dot / 2
                        color: here ? Theme.accent : occupied ? Colours.alpha(Colours.surfaceText, 0.55) : Colours.alpha(Colours.surfaceVariantText, 0.22)
                        scale: here ? 1.25 : 1

                        Behavior on scale {
                            NumberAnimation {
                                duration: Config.animDurationFast
                            }
                        }
                    }
                }
            }
        }
    }
}
