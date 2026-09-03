import QtQuick
import QtQuick.Effects
import Quickshell
import "../../config"
import "../../services"
import "../../components"

// Wallpaper clock: condensed time with a short accent rule and a spaced
// mono date underneath; a soft blurred shadow keeps it legible on light art.
Item {
    id: root

    readonly property string position: Config.desktopClock.position
    readonly property bool alignRight: position.endsWith("right")
    readonly property bool alignCenter: position.endsWith("center")
    readonly property int margin: Config.desktopClock.margin
    readonly property int size: Config.desktopClock.size

    width: face.width
    height: face.height
    x: alignRight ? parent.width - width - margin : alignCenter ? (parent.width - width) / 2 : margin
    y: position.startsWith("top") ? margin : parent.height - height - margin

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    Item {
        id: face

        width: Math.max(time.implicitWidth, dateRow.width)
        height: time.implicitHeight + 6 + dateRow.height
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 1.0
            shadowOpacity: 0.55
            shadowColor: Colours.scrim
            shadowVerticalOffset: 3
        }

        Text {
            id: time

            x: root.alignRight ? parent.width - implicitWidth : root.alignCenter ? (parent.width - implicitWidth) / 2 : 0
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: Colours.surfaceText
            font.family: "IBM Plex Sans Condensed"
            font.pixelSize: root.size
            font.weight: Font.Medium
            font.letterSpacing: -root.size * 0.03
            font.features: ({ "tnum": 1 })
            lineHeight: 0.82
            lineHeightMode: Text.ProportionalHeight
        }

        Row {
            id: dateRow

            x: root.alignRight ? parent.width - width : root.alignCenter ? (parent.width - width) / 2 : 0
            y: time.implicitHeight + 6
            spacing: 12

            Rectangle {
                width: root.size * 0.32
                height: 2
                radius: 1
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.accent
            }

            Text {
                text: Qt.formatDateTime(clock.date, "ddd d MMM").toUpperCase()
                color: Colours.surfaceText
                font.family: Theme.fontMono
                font.pixelSize: Math.round(root.size * 0.16)
                font.weight: Font.Medium
                font.letterSpacing: root.size * 0.03
            }
        }
    }
}
