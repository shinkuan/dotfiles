import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../config"
import "../../services"
import "../../components"
import "../popouts"
import "../notifications"

// Top-centre panel: calendar, what is next, notifications, media and usage.
// Frame style grows it out of the top band (a shader slot); other styles
// slide a Surface down from the edge.
Item {
    id: root

    required property HyprlandMonitor monitor
    property bool shown: false
    property bool shortcutActive: false   // opened by key / IPC: stays until Esc or a click outside
    readonly property bool frame: Theme.frame
    readonly property int pad: Config.padding + 4
    readonly property real edge: frame ? Config.borderThickness : 8
    readonly property bool sliding: y > -height + 1
    // slot for the frame shader, extended into the band so the join is straight
    readonly property vector4d blobRect: frame && (shown || sliding) ? Qt.vector4d(x, y - 40, width, height + 40) : Qt.vector4d(0, 0, 0, 0)

    x: Math.round((parent.width - width) / 2)
    y: shown ? edge : -height
    width: Config.dashboard.width
    height: body.implicitHeight + pad * 2
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
        if (!shown)
            Notifs.markAllRead();
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

        RowLayout {
            id: body

            x: root.pad
            y: root.pad
            width: root.width - root.pad * 2
            spacing: Config.padding + 8
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

            Loader {
                id: calendarColumn

                Layout.preferredWidth: 340
                Layout.alignment: Qt.AlignTop
                source: "CalendarColumn.qml"
                onLoaded: item.active = Qt.binding(() => root.shown)
            }

            ColumnLayout {
                Layout.preferredWidth: 340
                Layout.alignment: Qt.AlignTop
                spacing: 8

                Loader {
                    Layout.fillWidth: true
                    source: "UpNext.qml"
                }

                SectionLabel {
                    Layout.topMargin: 6
                    text: "Notifications"

                    Chip {
                        visible: Notifs.list.length > 0
                        icon: "clear_all"
                        text: "Clear"
                        onClicked: Notifs.clearAll()
                    }

                    Chip {
                        icon: ShellState.dnd ? "do_not_disturb_on" : "do_not_disturb_off"
                        text: "Do not disturb"
                        checked: ShellState.dnd
                        onClicked: ShellState.toggle("dnd")
                    }
                }

                StyledText {
                    visible: Notifs.list.length === 0
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 12
                    Layout.bottomMargin: 12
                    text: "No notifications"
                    color: Colours.surfaceVariantText
                }

                Repeater {
                    model: Notifs.list.slice(0, 4)

                    NotifCard {
                        required property var modelData

                        Layout.fillWidth: true
                        entry: modelData
                        compact: true
                        onDismissed: Notifs.remove(entry.key)
                    }
                }

                StyledText {
                    visible: Notifs.list.length > 4
                    Layout.alignment: Qt.AlignRight
                    text: `+${Notifs.list.length - 4} more`
                    color: Colours.outline
                    font.pixelSize: Config.fontSize - 2
                }
            }

            ColumnLayout {
                Layout.preferredWidth: 300
                Layout.alignment: Qt.AlignTop
                spacing: 8

                SectionLabel {
                    text: "Now playing"
                }

                MediaPopout {
                    Layout.fillWidth: true
                }

                Item {
                    Layout.preferredHeight: 4
                }

                ResourcesPopout {
                    Layout.fillWidth: true
                }
            }
        }
    }
}
