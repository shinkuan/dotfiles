import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../../config"
import "../../services"
import "../../components"

// Tray icons fold behind a chevron (bar.trayCompact) and unfold while hovered;
// hovering an icon opens its menu as a popout (see TrayMenuPopout).
Grid {
    id: root

    readonly property bool shown: SystemTray.items.values.length > 0
    readonly property bool compact: Config.bar.trayCompact
    readonly property bool horizontal: Theme.barTop
    readonly property Item bar: {
        let p = parent;
        while (p && p.activePopout === undefined)
            p = p.parent;
        return p;
    }
    readonly property bool menuOut: (bar?.activePopout ?? "").startsWith("tray:")
    property bool open: false
    readonly property bool expanded: !compact || open || menuOut

    flow: horizontal ? Grid.LeftToRight : Grid.TopToBottom
    columns: horizontal ? 99 : 1
    spacing: 2

    HoverHandler {
        onHoveredChanged: {
            if (hovered) {
                fold.stop();
                root.open = true;
            } else {
                fold.restart();
            }
        }
    }

    // grace period so the pointer can cross the gap between chevron and icons
    Timer {
        id: fold

        interval: 250
        onTriggered: root.open = false
    }

    Rectangle {
        id: toggle

        visible: root.compact
        width: root.horizontal ? 30 : Theme.barWidth - 8
        height: root.horizontal ? Theme.barWidth - 8 : 30
        radius: Config.radius
        color: toggleHover.hovered ? Colours.alpha(Colours.surfaceText, 0.08) : "transparent"

        MaterialIcon {
            anchors.centerIn: parent
            text: root.horizontal ? "chevron_right" : "expand_more"
            color: root.expanded ? Theme.accent : Colours.surfaceVariantText
            rotation: root.expanded ? 180 : 0

            Behavior on rotation {
                NumberAnimation {
                    duration: Theme.spatialDuration
                    easing.type: Theme.spatialType
                    easing.bezierCurve: Theme.spatialCurve
                }
            }
        }

        // item count while folded
        Rectangle {
            visible: !root.expanded
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 3
            width: 6
            height: 6
            radius: 3
            color: Theme.accent
        }

        HoverHandler {
            id: toggleHover
        }
    }

    Item {
        id: panel

        clip: true
        width: root.horizontal ? (root.expanded ? icons.implicitWidth : 0) : icons.implicitWidth
        height: root.horizontal ? icons.implicitHeight : (root.expanded ? icons.implicitHeight : 0)

        Behavior on width {
            enabled: root.horizontal
            NumberAnimation {
                duration: Theme.spatialDuration
                easing.type: Theme.spatialType
                easing.bezierCurve: Theme.spatialCurve
            }
        }

        Behavior on height {
            enabled: !root.horizontal
            NumberAnimation {
                duration: Theme.spatialDuration
                easing.type: Theme.spatialType
                easing.bezierCurve: Theme.spatialCurve
            }
        }

        Grid {
            id: icons

            flow: root.horizontal ? Grid.LeftToRight : Grid.TopToBottom
            columns: root.horizontal ? 99 : 1
            spacing: 2
            // anchored to the far end so the icons unfold away from the chevron
            x: root.horizontal ? panel.width - width : 0
            y: root.horizontal ? 0 : panel.height - height
            opacity: root.expanded ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Config.animDurationFast
                }
            }

            Repeater {
                model: SystemTray.items

                BarItem {
                    id: slot

                    required property SystemTrayItem modelData

                    // folded icons must not own a popout or the bar's hover hit test would find them
                    popout: root.expanded && modelData.hasMenu ? "tray:" + modelData.id : ""
                    pinOnClick: false

                    IconImage {
                        implicitSize: Config.iconSize - 2
                        source: slot.modelData.icon
                        asynchronous: true
                    }

                    WheelHandler {
                        onWheel: e => slot.modelData.scroll(e.angleDelta.y, false)
                    }

                    onClicked: m => {
                        if (m.button === Qt.LeftButton && !slot.modelData.onlyMenu)
                            slot.modelData.activate();
                        else if (m.button === Qt.MiddleButton)
                            slot.modelData.secondaryActivate();
                        else
                            slot.pin();
                    }
                }
            }
        }
    }
}
