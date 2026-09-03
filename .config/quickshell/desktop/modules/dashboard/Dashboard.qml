import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../config"
import "../../services"
import "../../components"

// Top-centre panel laid out as tiles: clock and notifications down the left,
// calendar over now-playing and usage in the middle, agenda over tasks on the
// right. Frame style grows it out of the top band (a shader slot); other
// styles slide a Surface down.
Item {
    id: root

    required property HyprlandMonitor monitor
    property bool shown: false
    property bool shortcutActive: false   // opened by key / IPC: stays until Esc or a click outside
    readonly property bool frame: Theme.frame
    readonly property int pad: 16
    readonly property int gap: 14
    readonly property real edge: frame ? Config.borderThickness : 8
    readonly property bool sliding: y > -height + 1
    // slot for the frame shader, extended into the band so the join is straight
    readonly property vector4d blobRect: frame && (shown || sliding) ? Qt.vector4d(x, y - 40, width, height + 40) : Qt.vector4d(0, 0, 0, 0)

    readonly property int infoWidth: 250
    readonly property int calendarWidth: 372
    readonly property int tallRow: 324
    readonly property int shortRow: 112

    x: Math.round((parent.width - width) / 2)
    y: shown ? edge : -height
    width: Config.dashboard.width
    height: tallRow + shortRow * 2 + gap * 2 + pad * 2
    visible: shown || sliding

    Behavior on y {
        NumberAnimation {
            duration: Theme.spatialDuration
            easing.type: Theme.spatialType
            easing.bezierCurve: Theme.spatialCurve
        }
    }

    function open(): void {
        closeGrace.stop();
        if (!shown) {
            Notifs.markAllRead();
            Calendar.refresh();
        }
        shown = true;
    }

    function close(): void {
        closeGrace.stop();
        shown = false;
        shortcutActive = false;
        todo.dropFocus();
    }

    function toggle(): void {
        if (shown)
            close();
        else {
            open();
            shortcutActive = true;
        }
    }

    function closeSoon(): void {
        if (shown && !shortcutActive)
            closeGrace.restart();
    }

    function contains(px: real, py: real): bool {
        return shown && px >= x && px < x + width && py >= y && py < y + height;
    }

    Timer {
        id: closeGrace

        interval: 250
        onTriggered: root.close()
    }

    Surface {
        anchors.fill: parent
        color: root.frame ? "transparent" : Theme.panel
        shadow: !root.frame

        // a click on bare panel takes keyboard focus away from the task field
        MouseArea {
            anchors.fill: parent
            onPressed: mouse => {
                todo.dropFocus();
                mouse.accepted = false;
            }
        }

        GridLayout {
            id: body

            x: root.pad
            y: root.pad
            width: root.width - root.pad * 2
            height: root.height - root.pad * 2
            columns: 3
            rows: 3
            columnSpacing: root.gap
            rowSpacing: root.gap
            // content settles in after the panel has come out
            opacity: root.shown ? 1 : 0

            Behavior on opacity {
                SequentialAnimation {
                    PauseAnimation {
                        duration: root.shown && root.frame ? 140 : 0
                    }

                    NumberAnimation {
                        duration: Config.animDurationFast
                    }
                }
            }

            InfoTile {
                Layout.row: 0
                Layout.column: 0
                Layout.rowSpan: 3
                Layout.preferredWidth: root.infoWidth
                Layout.fillHeight: true
                outerTL: true
                outerBL: true
            }

            DashTile {
                Layout.row: 0
                Layout.column: 1
                Layout.preferredWidth: root.calendarWidth
                Layout.preferredHeight: root.tallRow

                CalendarView {
                    id: cal

                    width: parent.width
                    height: parent.height
                    centeredHeader: true
                    rowHeight: 38
                    onSelectedChanged: events.selected = selected
                }
            }

            EventsTile {
                id: events

                Layout.row: 0
                Layout.column: 2
                Layout.fillWidth: true
                Layout.preferredHeight: root.tallRow
                outerTR: true
            }

            MediaTile {
                Layout.row: 1
                Layout.column: 1
                Layout.preferredWidth: root.calendarWidth
                Layout.preferredHeight: root.shortRow
            }

            UsageTile {
                Layout.row: 2
                Layout.column: 1
                Layout.preferredWidth: root.calendarWidth
                Layout.preferredHeight: root.shortRow
                active: root.shown
            }

            TodoTile {
                id: todo

                Layout.row: 1
                Layout.column: 2
                Layout.rowSpan: 2
                Layout.fillWidth: true
                Layout.fillHeight: true
                outerBR: true
            }
        }
    }
}
