import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../config"
import "../../services"

ColumnLayout {
    id: root

    spacing: 0

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDateTime(clock.date, "HH")
        color: Colours.onSurface
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSize + 2
        font.bold: true
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDateTime(clock.date, "mm")
        color: Colours.onSurface
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSize + 2
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 4
        text: Qt.formatDateTime(clock.date, "ddd")
        color: Colours.onSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSize - 3
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDateTime(clock.date, "d/M")
        color: Colours.onSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSize - 3
    }
}
