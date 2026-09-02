import QtQuick
import "../config"
import "../services"

Clickable {
    id: root

    property alias icon: icon.text
    property alias fill: icon.fill
    property color iconColor: Colours.surfaceVariantText
    property bool checked: false
    property int size: 32
    property int iconSize: Config.iconSize - 1

    implicitWidth: size
    implicitHeight: size
    radius: Theme.outlined ? Theme.radiusChip : size / 2
    baseColor: checked ? Theme.accent : "transparent"
    hoverColor: checked ? Colours.mix(Theme.accent, Theme.accentText, 0.12) : Colours.alpha(Colours.surfaceText, 0.08)
    pressColor: checked ? Colours.mix(Theme.accent, Theme.accentText, 0.24) : Colours.alpha(Colours.surfaceText, 0.14)

    MaterialIcon {
        id: icon

        anchors.centerIn: parent
        color: root.checked ? Theme.accentText : root.iconColor
        font.pixelSize: root.iconSize
    }
}
