import QtQuick
import "../config"
import "../services"

// Small pill button with optional icon; `checked` fills it with the accent.
Clickable {
    id: root

    property string icon: ""
    property string text: ""
    property bool checked: false
    property color accent: Colours.primary
    property color accentText: Colours.primaryText

    implicitHeight: 30
    implicitWidth: row.implicitWidth + 24
    radius: height / 2
    baseColor: checked ? accent : Colours.surfaceContainerHighest
    hoverColor: checked ? Colours.mix(accent, accentText, 0.12) : Colours.mix(Colours.surfaceContainerHighest, Colours.surfaceText, 0.08)
    pressColor: checked ? Colours.mix(accent, accentText, 0.24) : Colours.mix(Colours.surfaceContainerHighest, Colours.surfaceText, 0.14)

    Row {
        id: row

        anchors.centerIn: parent
        spacing: 6

        MaterialIcon {
            visible: root.icon !== ""
            text: root.icon
            font.pixelSize: Config.iconSize - 4
            color: root.checked ? root.accentText : Colours.surfaceVariantText
            anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
            visible: root.text !== ""
            text: root.text
            color: root.checked ? root.accentText : Colours.surfaceText
            font.pixelSize: Config.fontSize - 1
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
