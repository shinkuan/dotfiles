import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../config"
import "../../services"

Item {
    id: root

    required property HyprlandMonitor monitor
    property bool revealed: false
    readonly property real exposedWidth: width + x

    width: Config.barWidth
    x: revealed ? 0 : -width

    Behavior on x {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Colours.alpha(Colours.surface, 0.92)
        topRightRadius: Config.borderRounding
        bottomRightRadius: Config.borderRounding
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 12
        anchors.bottomMargin: 12
        spacing: 10

        KGridIndicator {
            Layout.alignment: Qt.AlignHCenter
            monitor: root.monitor
        }

        Item {
            Layout.fillHeight: true
        }

        Tray {
            Layout.alignment: Qt.AlignHCenter
        }

        StatusIcons {
            Layout.alignment: Qt.AlignHCenter
        }

        Clock {
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
