import QtQuick
import "../../config"
import "../../services"
import "../../components"

BarItem {
    popout: "notifications"

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        width: Config.iconSize
        height: Config.iconSize

        MaterialIcon {
            anchors.centerIn: parent
            text: ShellState.dnd ? "notifications_off" : Notifs.unread > 0 ? "notifications_unread" : "notifications"
            color: ShellState.dnd ? Colours.outline : Notifs.unread > 0 ? Theme.accent : Colours.surfaceText
        }

        Rectangle {
            visible: Notifs.unread > 0 && !ShellState.dnd
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: -4
            anchors.topMargin: -4
            width: Math.max(14, badge.implicitWidth + 6)
            height: 14
            radius: 7
            color: Colours.error

            StyledText {
                id: badge

                anchors.centerIn: parent
                text: Notifs.unread > 99 ? "99+" : Notifs.unread
                color: Colours.errorText
                font.pixelSize: 9
                font.weight: Font.Bold
            }
        }
    }
}
