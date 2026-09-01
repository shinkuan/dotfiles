import QtQuick
import "../config"
import "../services"

// Material-style switch
Item {
    id: root

    property bool checked: false
    signal toggled(bool checked)

    implicitWidth: 44
    implicitHeight: 24

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Colours.primary : Colours.surfaceContainerHighest
        border.width: root.checked ? 0 : 2
        border.color: Colours.outline

        Behavior on color {
            ColorAnimation {
                duration: Config.animDurationFast
            }
        }
    }

    Rectangle {
        x: root.checked ? parent.width - width - 3 : 4
        anchors.verticalCenter: parent.verticalCenter
        width: root.checked ? 18 : 14
        height: width
        radius: width / 2
        color: root.checked ? Colours.onPrimary : Colours.outline

        Behavior on x {
            NumberAnimation {
                duration: Config.animDurationFast
                easing.type: Easing.OutCubic
            }
        }
        Behavior on width {
            NumberAnimation {
                duration: Config.animDurationFast
            }
        }
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.toggled(!root.checked)
    }
}
