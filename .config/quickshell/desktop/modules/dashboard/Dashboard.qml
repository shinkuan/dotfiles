import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../config"
import "../../services"
import "../../components"

// Top-centre panel laid out as tiles: weather and usage on top, calendar and
// the day's agenda below, media down the right side. Frame style grows it
// out of the top band (a shader slot); other styles slide a Surface down.
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

    readonly property int topRow: 150
    readonly property int bottomRow: 384
    readonly property int mediaWidth: 250
    readonly property int calendarWidth: 380

    x: Math.round((parent.width - width) / 2)
    y: shown ? edge : -height
    width: Config.dashboard.width
    height: topRow + gap + bottomRow + pad * 2
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
            Weather.refresh(false);
        }
        shown = true;
    }

    function close(): void {
        closeGrace.stop();
        shown = false;
        shortcutActive = false;
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

        GridLayout {
            id: body

            x: root.pad
            y: root.pad
            width: root.width - root.pad * 2
            height: root.height - root.pad * 2
            columns: 3
            rows: 2
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

            WeatherTile {
                Layout.preferredWidth: root.calendarWidth
                Layout.preferredHeight: root.topRow
            }

            UsageTile {
                Layout.fillWidth: true
                Layout.preferredHeight: root.topRow
                active: root.shown
            }

            MediaTile {
                Layout.preferredWidth: root.mediaWidth
                Layout.rowSpan: 2
                Layout.fillHeight: true
            }

            DashTile {
                Layout.preferredWidth: root.calendarWidth
                Layout.preferredHeight: root.bottomRow

                CalendarView {
                    id: cal

                    width: parent.width
                    height: parent.height
                    centeredHeader: true
                    // header + weekday row + spacings, the rest is six equal rows
                    rowHeight: Math.floor((parent.height - 32 - 6 - 20 - 6 - 5 * gap) / 6)
                    onSelectedChanged: events.selected = selected
                }
            }

            EventsTile {
                id: events

                Layout.fillWidth: true
                Layout.preferredHeight: root.bottomRow
            }
        }
    }
}
