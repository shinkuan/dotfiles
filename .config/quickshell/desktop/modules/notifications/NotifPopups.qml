import QtQuick
import Quickshell.Hyprland
import "../../config"
import "../../services"

// Popup stack in the top-right corner of the focused monitor. Frame style:
// the stack is a panel welded to the side band (a shader slot), the cards are
// raised tiles on it and each one slides out from under the band.
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
    readonly property bool frame: Theme.frame
    readonly property int pad: frame ? 10 : 0
    // frame: flush against the band, so the shader can weld the two together
    readonly property int band: frame ? Config.borderThickness : 16
    // slot for the frame shader, extended into the band so the join is straight
    readonly property vector4d blobRect: frame && height > 0 ? Qt.vector4d(atLeft ? x - 40 : x, y, width + 40, height) : Qt.vector4d(0, 0, 0, 0)

    anchors.top: atBottom ? undefined : parent.top
    anchors.bottom: atBottom ? parent.bottom : undefined
    anchors.right: atLeft ? undefined : parent.right
    anchors.left: atLeft ? parent.left : undefined
    anchors.topMargin: band + (Theme.barTop && ShellState.barPinned ? Config.barWidth : 0)
    anchors.bottomMargin: band
    anchors.leftMargin: band + (!Theme.barTop && !Theme.barRight && ShellState.barPinned ? Config.barWidth : 0)
    anchors.rightMargin: band + (Theme.barRight && ShellState.barPinned ? Config.barWidth : 0)
    width: Config.notifications.width + pad * 2
    height: column.implicitHeight > 0 ? column.implicitHeight + pad * 2 : 0
    visible: height > 0
    // cards enter from under the band, so they must not paint over it
    clip: frame

    // the panel grows and retracts with the stack instead of snapping
    Behavior on height {
        enabled: root.frame
        NumberAnimation {
            duration: Theme.spatialDuration
            easing.type: Theme.spatialType
            easing.bezierCurve: Theme.spatialCurve
        }
    }

    Column {
        id: column

        x: root.pad
        y: root.pad
        width: root.width - root.pad * 2
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
                from: root.frame ? (root.atLeft ? -root.width : root.width) : root.atLeft ? -60 : 60
                to: 0
                duration: root.frame ? Theme.spatialDuration : Config.animDuration
                easing.type: root.frame ? Theme.spatialType : Easing.OutCubic
                easing.bezierCurve: Theme.spatialCurve
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
