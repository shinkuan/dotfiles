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
        visible: root.horizontal
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(clock.date, "HH:mm")
        font.family: root.face
        font.pixelSize: Config.fontSize + 1
        font.weight: Theme.ledger ? Font.Medium : Font.DemiBold
        color: Theme.signal ? root.fgAccent : root.fg
    }

    StyledText {
        visible: root.horizontal
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(clock.date, "ddd d/M")
        color: root.filled ? root.fgDim : Colours.surfaceVariantText
        font.pixelSize: Config.fontSize - 2
    }

    StyledText {
        visible: !root.horizontal
        anchors.horizontalCenter: Theme.barTop ? undefined : parent.horizontalCenter
        anchors.verticalCenter: Theme.barTop ? parent.verticalCenter : undefined
        text: Qt.formatDateTime(clock.date, "HH")
        font.family: root.face
        font.pixelSize: Config.fontSize + 2
        font.weight: Theme.ledger ? Font.Medium : Font.Bold
        color: Theme.signal ? root.fgAccent : root.fg
    }

    StyledText {
        visible: !root.horizontal
        anchors.horizontalCenter: Theme.barTop ? undefined : parent.horizontalCenter
        anchors.verticalCenter: Theme.barTop ? parent.verticalCenter : undefined
        text: Qt.formatDateTime(clock.date, "mm")
        font.family: root.face
        font.pixelSize: Config.fontSize + 2
        color: Theme.signal ? root.fgAccent : root.fg
    }

    StyledText {
        visible: !root.horizontal
        anchors.horizontalCenter: Theme.barTop ? undefined : parent.horizontalCenter
        anchors.verticalCenter: Theme.barTop ? parent.verticalCenter : undefined
        topPadding: 4
        text: Qt.formatDateTime(clock.date, "ddd")
        color: root.filled ? root.fgDim : Colours.surfaceVariantText
        font.pixelSize: Config.fontSize - 3
    }

    StyledText {
        visible: !root.horizontal
        anchors.horizontalCenter: Theme.barTop ? undefined : parent.horizontalCenter
        anchors.verticalCenter: Theme.barTop ? parent.verticalCenter : undefined
        text: Qt.formatDateTime(clock.date, "d/M")
        color: root.filled ? root.fgDim : Colours.surfaceVariantText
        font.pixelSize: Config.fontSize - 3
    }
}
