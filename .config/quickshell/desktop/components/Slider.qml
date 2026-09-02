import QtQuick
import "../config"
import "../services"

// Horizontal 0..1 slider: click/drag to set, wheel to nudge.
Item {
    id: root

    property real value: 0
    property real wheelStep: 0.05
    property color accent: Theme.accent
    property bool interactive: true
    signal moved(real value)

    implicitHeight: 22
    implicitWidth: 120

    function setFromX(x: real): void {
        root.moved(Math.max(0, Math.min(1, x / width)));
    }

    Rectangle {
        visible: !Theme.segmented
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: (Theme.capsule || Theme.poster) ? 10 : Theme.ledger ? 4 : 6
        radius: (Theme.ledger || Theme.poster) ? 0 : height / 2
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

    // Signal: tick-mark meter
    Row {
        visible: Theme.segmented
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        spacing: 2

        Repeater {
            model: Math.max(1, Math.floor((root.width + 2) / 8))

            Rectangle {
                required property int index

                width: 6
                height: 8
                color: index < Math.round(root.value * Math.floor((root.width + 2) / 8)) ? root.accent : Colours.surfaceContainerHighest
            }
        }
    }

    Rectangle {
        x: Math.max(0, Math.min(parent.width - width, parent.width * root.value - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        width: mouse.pressed ? 4 : 3
        height: mouse.pressed ? 22 : 16
        radius: 2
        color: Theme.capsule ? Colours.surfaceText : root.accent
        visible: root.interactive && !Theme.segmented && !Theme.poster

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
