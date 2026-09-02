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

    readonly property string position: Config.notifications.position
    readonly property bool atBottom: position.startsWith("bottom")
    readonly property bool atLeft: position.endsWith("left")

    anchors.top: atBottom ? undefined : parent.top
    anchors.bottom: atBottom ? parent.bottom : undefined
    anchors.right: atLeft ? undefined : parent.right
    anchors.left: atLeft ? parent.left : undefined
    anchors.margins: 16
    anchors.topMargin: 16 + (Theme.barTop && ShellState.barPinned ? Config.barWidth : 0)
    anchors.leftMargin: 16 + (!Theme.barTop && !Theme.barRight && ShellState.barPinned ? Config.barWidth : 0)
    anchors.rightMargin: 16 + (Theme.barRight && ShellState.barPinned ? Config.barWidth : 0)
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
                from: root.atLeft ? -60 : 60
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
