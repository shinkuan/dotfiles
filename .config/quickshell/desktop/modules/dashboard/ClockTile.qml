import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../config"
import "../../services"
import "../../components"

// Time and date, centred.
DashTile {
    id: root

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 6

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            font.pixelSize: 52
            font.weight: Font.DemiBold
            font.letterSpacing: -1.5
            lineHeight: 0.9
            lineHeightMode: Text.ProportionalHeight
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: root.innerWidth
            text: Qt.formatDate(clock.date, "dddd, d MMMM")
            color: Colours.surfaceVariantText
            font.pixelSize: Config.fontSize + 1
            elide: Text.ElideRight
        }
    }
}
