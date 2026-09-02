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


    readonly property string face: (Theme.ledger || Theme.signal) ? Theme.fontMono : Theme.font

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(clock.date, "HH")
        font.family: root.face
        font.pixelSize: Config.fontSize + 2
        font.weight: Theme.ledger ? Font.Medium : Font.Bold
        color: Theme.signal ? Theme.accent : Colours.surfaceText
    }

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(clock.date, "mm")
        font.family: root.face
        font.pixelSize: Config.fontSize + 2
        color: Theme.signal ? Theme.accent : Colours.surfaceText
    }

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        topPadding: 4
        text: Qt.formatDateTime(clock.date, "ddd")
        color: Colours.surfaceVariantText
        font.pixelSize: Config.fontSize - 3
    }

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(clock.date, "d/M")
        color: Colours.surfaceVariantText
        font.pixelSize: Config.fontSize - 3
    }
}
