import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../config"
import "../../services"
import "../../components"
import "../notifications"

// Clock, the selected day's events, what is next, and the latest notifications.
DashTile {
    id: root

    property date selected: Calendar.today
    readonly property bool isToday: Qt.formatDate(selected, "yyyy-MM-dd") === Qt.formatDate(Calendar.today, "yyyy-MM-dd")
    readonly property list<var> dayEvents: Calendar.eventMap ? Calendar.eventsOn(selected) : []
    // what the day section already shows is not repeated under "Up next"
    readonly property list<var> next: Calendar.eventMap ? Calendar.upcoming(Config.calendar.upcomingDays).filter(e => !root.dayEvents.some(d => d.id === e.id && Calendar.dayKey(d.s) === Calendar.dayKey(e.s))) : []
    readonly property int notifShown: 2

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            StyledText {
                text: Qt.formatDateTime(clock.date, "HH:mm")
                font.family: Theme.fontLabel
                font.pixelSize: 34
                font.weight: Font.DemiBold
                lineHeight: 0.9
                lineHeightMode: Text.ProportionalHeight
            }

            StyledText {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignBaseline
                text: Qt.formatDate(clock.date, "dddd, d MMMM")
                color: Colours.surfaceVariantText
                font.pixelSize: Config.fontSize + 1
                elide: Text.ElideRight
            }
        }

        SectionLabel {
            Layout.topMargin: 4
            text: root.isToday ? "Today" : Qt.formatDate(root.selected, "dddd d MMMM")
        }

        EventList {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(implicitHeight, rowHeight * 3)
            events: root.dayEvents
            grouped: false
            emptyText: root.isToday ? "Nothing on today" : "Nothing on this day"
        }

        SectionLabel {
            Layout.topMargin: 4
            text: "Up next"
        }

        EventList {
            id: nextList

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: rowHeight * 2
            events: root.next
            grouped: true
            emptyText: "Nothing scheduled"

            // a cut row reads as a bug; fade the overflow instead
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 28
                visible: nextList.implicitHeight > nextList.height
                gradient: Gradient {
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 1; color: Colours.surfaceContainer }
                }
            }
        }

        SectionLabel {
            Layout.topMargin: 4
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
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            text: "No notifications"
            color: Colours.surfaceVariantText
        }

        Repeater {
            model: Notifs.list.slice(0, root.notifShown)

            NotifCard {
                required property var modelData

                Layout.fillWidth: true
                entry: modelData
                compact: true
                onDismissed: Notifs.remove(entry.key)
            }
        }

        StyledText {
            visible: Notifs.list.length > root.notifShown
            Layout.alignment: Qt.AlignRight
            text: `+${Notifs.list.length - root.notifShown} more`
            color: Colours.outline
            font.pixelSize: Config.fontSize - 2
        }
    }
}
