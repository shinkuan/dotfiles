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
    property color accent: ratio > 0.9 ? Colours.error : Theme.accent

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

    Slider {
        Layout.fillWidth: true
        value: root.ratio
        accent: root.accent
        interactive: false
        implicitHeight: 12
    }
}
