import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../config"
import "../../services"
import "../../components"

Item {
    id: root

    readonly property string position: Config.desktopClock.position
    readonly property bool alignRight: position.endsWith("right")
    readonly property bool alignCenter: position.endsWith("center")
    readonly property int margin: Config.desktopClock.margin
    readonly property int align: alignRight ? Qt.AlignRight : alignCenter ? Qt.AlignHCenter : Qt.AlignLeft

    width: column.implicitWidth
    height: column.implicitHeight
    x: alignRight ? parent.width - width - margin : alignCenter ? (parent.width - width) / 2 : margin
    y: position.startsWith("top") ? margin : parent.height - height - margin

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    // an offset copy in scrim keeps the clock legible on light wallpapers
    component ClockColumn: ColumnLayout {
        property bool shadow: false

        x: shadow ? 2 : 0
        y: shadow ? 3 : 0
        opacity: shadow ? 0.5 : 1
        spacing: 0

        StyledText {
            Layout.alignment: root.align
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: parent.shadow ? Colours.scrim : Colours.surfaceText
            font.pixelSize: 84
            font.weight: Font.Light
            font.letterSpacing: 2
        }

        StyledText {
            Layout.alignment: root.align
            text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
            color: parent.shadow ? Colours.scrim : Colours.surfaceVariantText
            font.pixelSize: 22
        }
    }

    ClockColumn {
        shadow: true
    }

    ClockColumn {
        id: column
    }

}
