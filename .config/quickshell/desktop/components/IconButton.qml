import QtQuick
import "../config"
import "../services"

Clickable {
    id: root

    property alias icon: icon.text
    property alias fill: icon.fill
    property color iconColor: Colours.onSurfaceVariant
    property bool checked: false
    property int size: 32
    property int iconSize: Config.iconSize - 1

    implicitWidth: size
    implicitHeight: size
    radius: size / 2
    baseColor: checked ? Colours.primary : "transparent"
    hoverColor: checked ? Colours.mix(Colours.primary, Colours.onPrimary, 0.12) : Colours.alpha(Colours.onSurface, 0.08)
    pressColor: checked ? Colours.mix(Colours.primary, Colours.onPrimary, 0.24) : Colours.alpha(Colours.onSurface, 0.14)

    MaterialIcon {
        id: icon

        anchors.centerIn: parent
        color: root.checked ? Colours.onPrimary : root.iconColor
        font.pixelSize: root.iconSize
    }
}
