import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../components"

ColumnLayout {
    spacing: 8

    SectionLabel {
        text: "Up next"
    }

    EventList {
        Layout.fillWidth: true
        Layout.preferredHeight: 150
        events: Calendar.upcoming(Config.calendar?.upcomingDays ?? 7)
        grouped: true
        emptyText: "Nothing scheduled"
    }
}
