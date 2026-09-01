import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"

// label ........ value  +  progress bar
ColumnLayout {
    id: root

    property string icon: ""
    property string label: ""
    property string value: ""
    property real ratio: 0
    property color accent: ratio > 0.9 ? Colours.error : Colours.primary

    spacing: 4
    Layout.fillWidth: true

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        MaterialIcon {
            visible: root.icon !== ""
            text: root.icon
            font.pixelSize: Config.iconSize - 3
            color: Colours.surfaceVariantText
        }

        StyledText {
            Layout.fillWidth: true
            text: root.label
        }

        StyledText {
            text: root.value
            color: Colours.surfaceVariantText
            font.family: Config.fontFamilyMono
            font.pixelSize: Config.fontSize - 1
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 6
        radius: 3
        color: Colours.surfaceContainerHighest

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.ratio))
            height: parent.height
            radius: parent.radius
            color: root.accent

            Behavior on width {
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
