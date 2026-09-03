import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import "../../config"
import "../../services"
import "../../components"

// Wallpaper clock in the caelestia manner: hours and minutes in two palette
// tones around a lifted colon, a short vertical rule, then month / day /
// weekday stacked beside it. `desktopClock.size` is the time's pixel size;
// everything else scales with it. A soft shadow keeps it legible on light art.
Item {
    id: root

    readonly property string position: Config.desktopClock.position
    readonly property bool alignRight: position.endsWith("right")
    readonly property bool alignCenter: position.endsWith("center")
    readonly property int margin: Config.desktopClock.margin
    readonly property int size: Config.desktopClock.size
    readonly property real k: size / 112

    width: face.implicitWidth
    height: face.implicitHeight
    x: alignRight ? parent.width - width - margin : alignCenter ? (parent.width - width) / 2 : margin
    y: position.startsWith("top") ? margin : parent.height - height - margin

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    RowLayout {
        id: face

        spacing: Math.round(14 * root.k)
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 0.46
            shadowOpacity: 0.62
            shadowColor: Colours.scrim
        }

        RowLayout {
            spacing: Math.round(4 * root.k)

            Text {
                text: Qt.formatDateTime(clock.date, "HH")
                color: Colours.primary
                font.family: "Rubik"
                font.pixelSize: root.size
                font.weight: Font.Bold
            }

            Text {
                Layout.topMargin: -Math.round(root.size * 0.16)
                text: ":"
                color: Colours.tertiary
                opacity: 0.8
                font.family: "Rubik"
                font.pixelSize: root.size
            }

            Text {
                text: Qt.formatDateTime(clock.date, "mm")
                color: Colours.secondary
                font.family: "Rubik"
                font.pixelSize: root.size
                font.weight: Font.Bold
            }
        }

        Rectangle {
            Layout.fillHeight: true
            Layout.topMargin: Math.round(14 * root.k)
            Layout.bottomMargin: Math.round(14 * root.k)
            Layout.preferredWidth: Math.max(2, Math.round(4 * root.k))
            radius: width / 2
            color: Colours.primary
            opacity: 0.8
        }

        ColumnLayout {
            spacing: 0

            Text {
                text: Qt.formatDateTime(clock.date, "MMMM").toUpperCase()
                color: Colours.secondary
                font.family: "Rubik"
                font.pixelSize: Math.round(root.size * 0.19)
                font.weight: Font.Bold
                font.letterSpacing: 4 * root.k
            }

            Text {
                text: Qt.formatDateTime(clock.date, "dd")
                color: Colours.primary
                font.family: "Rubik"
                font.pixelSize: Math.round(root.size / 3)
                font.weight: Font.Medium
                font.letterSpacing: 2 * root.k
            }

            Text {
                text: Qt.formatDateTime(clock.date, "dddd")
                color: Colours.secondary
                font.family: "Rubik"
                font.pixelSize: Math.round(root.size * 0.19)
                font.letterSpacing: 2 * root.k
            }
        }
    }
}
