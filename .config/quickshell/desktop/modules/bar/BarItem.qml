import QtQuick
import "../../config"
import "../../services"

// A bar entry. `popout` names the popout revealed on hover (empty = none).
// Content is laid out in a centred Column.
Rectangle {
    id: root

    property string popout: ""
    property int spacing: 2
    default property alias content: column.data
    readonly property alias hovered: hover.hovered
    readonly property Item bar: {
        let p = parent;
        while (p && p.activePopout === undefined)
            p = p.parent;
        return p;
    }
    readonly property bool active: popout !== "" && bar !== null && bar.activePopout === popout

    signal clicked(var mouse)

    implicitWidth: Config.barWidth - 8
    implicitHeight: column.implicitHeight + 10
    radius: Config.radius
    color: active ? Colours.alpha(Colours.primary, 0.18) : hover.hovered ? Colours.alpha(Colours.surfaceText, 0.08) : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: Config.animDurationFast
        }
    }

    Column {
        id: column

        anchors.centerIn: parent
        spacing: root.spacing
    }

    HoverHandler {
        id: hover
    }

    MouseArea {
        property real pressX: -1

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onPressed: m => pressX = m.x
        onReleased: pressX = -1
        onPositionChanged: m => {
            if (pressX >= 0 && root.bar)
                root.bar.dragged(m.x - pressX);
        }
        onClicked: m => root.clicked(m)
    }
}
