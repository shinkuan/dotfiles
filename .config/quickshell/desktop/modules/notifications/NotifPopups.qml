import QtQuick
import Quickshell.Hyprland
import "../../config"
import "../../services"

// Popup stack in the top-right corner of the focused monitor.
Item {
    id: root

    required property HyprlandMonitor monitor
    readonly property bool focused: monitor?.focused ?? false
    readonly property list<var> entries: focused ? Notifs.popups.slice(0, 5).map(key => Notifs.find(key)).filter(e => e !== null) : []
    // keyboard focus is only worth taking while a reply field can be used
    readonly property bool needsKeyboard: entries.some(e => e.hasInlineReply && e.notif)

    anchors.top: parent.top
    anchors.right: parent.right
    anchors.margins: 16
    width: Config.notifications.width
    height: column.implicitHeight
    visible: entries.length > 0

    Column {
        id: column

        width: parent.width
        spacing: 8
        add: Transition {
            NumberAnimation {
                properties: "opacity"
                from: 0
                to: 1
                duration: Config.animDuration
            }
            NumberAnimation {
                properties: "x"
                from: 60
                to: 0
                duration: Config.animDuration
                easing.type: Easing.OutCubic
            }
        }
        move: Transition {
            NumberAnimation {
                properties: "y"
                duration: Config.animDuration
                easing.type: Easing.OutCubic
            }
        }

        Repeater {
            model: root.entries

            NotifCard {
                required property var modelData

                width: column.width
                entry: modelData
                onDismissed: Notifs.dismiss(entry.key)
                onSwiped: Notifs.hidePopup(entry.key)
            }
        }
    }
}
