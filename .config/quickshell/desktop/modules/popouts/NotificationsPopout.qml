import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../components"
import "../notifications"

ColumnLayout {
    id: root

    width: Config.notifications.width
    spacing: 8

    Component.onCompleted: Notifs.markAllRead()

    SectionLabel {
        text: "Notifications"

        Chip {
            visible: Notifs.list.length > 0
            icon: "clear_all"
            text: "Clear"
            onClicked: Notifs.clearAll()
        }

        Chip {
            icon: ShellState.dnd ? "do_not_disturb_on" : "do_not_disturb_off"
            text: "Do not disturb"
            checked: ShellState.dnd
            onClicked: ShellState.toggle("dnd")
        }
    }

    StyledText {
        visible: Notifs.list.length === 0
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 24
        Layout.bottomMargin: 24
        text: "No notifications"
        color: Colours.surfaceVariantText
    }

    ListView {
        id: list

        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(560, contentHeight)
        visible: Notifs.list.length > 0
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: Notifs.list
        spacing: 6

        delegate: NotifCard {
            required property var modelData

            width: list.width
            entry: modelData
            compact: true
            onDismissed: Notifs.remove(entry.key)
        }
    }
}
