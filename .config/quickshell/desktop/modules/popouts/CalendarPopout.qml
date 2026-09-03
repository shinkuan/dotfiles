import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../components"

// Month view with event dots; the selected day's events underneath.
ColumnLayout {
    id: root

    width: 7 * 38 + 6 * 2
    spacing: 8

    CalendarView {
        id: cal

        Layout.fillWidth: true
        Layout.preferredWidth: root.width
    }

    EventList {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(implicitHeight, 4 * rowHeight)
        events: Calendar.eventsOn(cal.selected)
        grouped: false
        emptyText: Qt.formatDate(cal.selected, "d MMM") + " · nothing scheduled"
    }
}
