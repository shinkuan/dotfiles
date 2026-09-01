import QtQuick
import Quickshell
import "../../config"
import "../../services"
import "../../components"

BarItem {
    id: root

    popout: "calendar"
    spacing: 0

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(clock.date, "HH")
        font.pixelSize: Config.fontSize + 2
        font.weight: Font.Bold
    }

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(clock.date, "mm")
        font.pixelSize: Config.fontSize + 2
    }

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        topPadding: 4
        text: Qt.formatDateTime(clock.date, "ddd")
        color: Colours.onSurfaceVariant
        font.pixelSize: Config.fontSize - 3
    }

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(clock.date, "d/M")
        color: Colours.onSurfaceVariant
        font.pixelSize: Config.fontSize - 3
    }
}
