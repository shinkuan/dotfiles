import QtQuick
import "../config"
import "../services"

// Small pill button with optional icon; `checked` fills it with the accent.
Clickable {
    id: root

    property string icon: ""
    property string text: ""
    property bool checked: false
    property color accent: Theme.accent
    property color accentText: Theme.accentText

    implicitHeight: Theme.capsule ? 32 : 30
    implicitWidth: row.implicitWidth + 24
    radius: Theme.radiusChip === 999 ? height / 2 : Theme.radiusChip
    baseColor: checked ? (Theme.outlined ? Colours.alpha(accent, Theme.signal ? 1 : 0) : Theme.capsule ? Colours.primaryContainer : accent) : Theme.outlined ? "transparent" : Theme.field
    hoverColor: checked ? Colours.mix(baseColor, accentText, 0.12) : Colours.mix(Theme.field, Colours.surfaceText, 0.08)
    pressColor: checked ? Colours.mix(baseColor, accentText, 0.24) : Colours.mix(Theme.field, Colours.surfaceText, 0.14)
    border.width: Theme.outlined ? 1 : 0
    border.color: checked ? accent : Colours.outlineVariant

    Row {
        id: row

        anchors.centerIn: parent
        spacing: 6

        MaterialIcon {
            visible: root.icon !== ""
            text: root.icon
            font.pixelSize: Config.iconSize - 4
            color: root.checked ? (Theme.ledger ? root.accent : Theme.capsule ? Colours.primaryContainerText : root.accentText) : Colours.surfaceVariantText
            anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
            visible: root.text !== ""
            text: root.text
            color: root.checked ? (Theme.ledger ? root.accent : Theme.capsule ? Colours.primaryContainerText : root.accentText) : Colours.surfaceText
            font.pixelSize: Config.fontSize - (Theme.outlined ? 2 : 1)
            font.capitalization: (Theme.outlined || Theme.solid) ? Font.AllUppercase : Font.MixedCase
            font.letterSpacing: (Theme.outlined || Theme.solid) ? 0.8 : 0
            font.weight: Theme.solid ? Font.DemiBold : Font.Normal
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
