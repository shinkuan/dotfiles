import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../components"

// Month grid plus the selected day's events. Loaded separately so the
// calendar layer can be absent without taking the rest of the panel down.
ColumnLayout {
    id: root

    property bool active: false

    spacing: 8

    onActiveChanged: {
        if (active)
            Calendar.refresh();
    }

    CalendarView {
        id: cal

        Layout.fillWidth: true
    }

    SectionLabel {
        Layout.topMargin: 4
        text: Qt.formatDate(cal.selected, "dddd d MMMM")
    }

    EventList {
        Layout.fillWidth: true
        Layout.preferredHeight: 120
        events: Calendar.eventsOn(cal.selected)
        grouped: false
        emptyText: "Nothing on this day"
    }
}
