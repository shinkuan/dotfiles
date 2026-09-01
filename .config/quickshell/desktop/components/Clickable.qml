import QtQuick
import "../config"
import "../services"

// Hover / press feedback surface. Hover comes from a non-blocking
// HoverHandler so the shell's full-screen tracker keeps receiving motion.
Rectangle {
    id: root

    readonly property alias hovered: hover.hovered
    readonly property alias pressed: mouse.pressed
    property bool disabled: false
    property color baseColor: "transparent"
    property color hoverColor: Colours.alpha(Colours.surfaceText, 0.08)
    property color pressColor: Colours.alpha(Colours.surfaceText, 0.14)
    property int acceptedButtons: Qt.LeftButton

    signal clicked(var mouse)

    radius: Config.radius
    color: disabled ? baseColor : pressed ? pressColor : hovered ? hoverColor : baseColor
    opacity: disabled ? 0.5 : 1

    Behavior on color {
        ColorAnimation {
            duration: Config.animDurationFast
        }
    }

    HoverHandler {
        id: hover

        enabled: !root.disabled
        cursorShape: Qt.PointingHandCursor
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        enabled: !root.disabled
        acceptedButtons: root.acceptedButtons
        onClicked: m => root.clicked(m)
    }
}
