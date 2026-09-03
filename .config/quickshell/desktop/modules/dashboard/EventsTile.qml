import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../components"

// The selected day's events and what comes next.
DashTile {
    id: root

    property date selected: Calendar.today
    readonly property bool isToday: Qt.formatDate(selected, "yyyy-MM-dd") === Qt.formatDate(Calendar.today, "yyyy-MM-dd")
    readonly property list<var> dayEvents: Calendar.eventMap ? Calendar.eventsOn(selected) : []
    // what the day section already shows is not repeated under "Up next"
    readonly property list<var> next: Calendar.eventMap ? Calendar.upcoming(Config.calendar.upcomingDays).filter(e => !root.dayEvents.some(d => d.id === e.id && Calendar.dayKey(d.s) === Calendar.dayKey(e.s))) : []

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        SectionLabel {
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
    }
}
