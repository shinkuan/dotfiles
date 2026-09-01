import QtQuick
import "../config"
import "../services"

// Horizontal 0..1 slider: click/drag to set, wheel to nudge.
Item {
    id: root

    property real value: 0
    property real wheelStep: 0.05
    property color accent: Colours.primary
    property bool interactive: true
    signal moved(real value)

    implicitHeight: 22
    implicitWidth: 120

    function setFromX(x: real): void {
        root.moved(Math.max(0, Math.min(1, x / width)));
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Colours.surfaceContainerHighest

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.value))
            height: parent.height
            radius: parent.radius
            color: root.accent

            Behavior on width {
                enabled: !mouse.pressed
                NumberAnimation {
                    duration: Config.animDurationFast
                }
            }
        }
    }

    Rectangle {
        x: Math.max(0, Math.min(parent.width - width, parent.width * root.value - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        width: mouse.pressed ? 4 : 3
        height: mouse.pressed ? 22 : 16
        radius: 2
        color: root.accent
        visible: root.interactive

        Behavior on x {
            enabled: !mouse.pressed
            NumberAnimation {
                duration: Config.animDurationFast
            }
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        enabled: root.interactive
        onPressed: m => root.setFromX(m.x)
        onPositionChanged: m => {
            if (pressed)
                root.setFromX(m.x);
        }
    }

    WheelHandler {
        enabled: root.interactive
        onWheel: e => root.moved(Math.max(0, Math.min(1, root.value + (e.angleDelta.y > 0 ? root.wheelStep : -root.wheelStep))))
    }
}
