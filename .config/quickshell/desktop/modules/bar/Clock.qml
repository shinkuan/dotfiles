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
        id: hh

        visible: root.horizontal
        text: Qt.formatDateTime(clock.date, "HH:mm")
        font.family: root.face
        font.pixelSize: Config.fontSize + 1
        font.weight: Theme.ledger ? Font.Medium : Font.DemiBold
        color: Theme.signal ? root.fgAccent : root.fg
    }

    StyledText {
        visible: !root.horizontal
        text: Qt.formatDateTime(clock.date, "HH")
        font.family: root.face
        font.pixelSize: Config.fontSize + 2
        font.weight: Theme.ledger ? Font.Medium : Font.Bold
        color: Theme.signal ? root.fgAccent : root.fg
    }

    StyledText {
        visible: !root.horizontal
        text: Qt.formatDateTime(clock.date, "mm")
        font.family: root.face
        font.pixelSize: Config.fontSize + 2
        color: Theme.signal ? root.fgAccent : root.fg
    }
}
