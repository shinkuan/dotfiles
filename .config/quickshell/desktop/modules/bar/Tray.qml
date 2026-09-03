import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../../config"
import "../../services"
import "../../components"

// Tray icons fold behind a chevron (bar.trayCompact); the open state persists.
Grid {
    id: root

    readonly property bool shown: SystemTray.items.values.length > 0
    readonly property bool compact: Config.bar.trayCompact
    readonly property bool expanded: !compact || ShellState.trayExpanded
    readonly property bool horizontal: Theme.barTop

    flow: horizontal ? Grid.LeftToRight : Grid.TopToBottom
    columns: horizontal ? 99 : 1
    spacing: 2

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

        MouseArea {
            anchors.fill: parent
            onClicked: ShellState.toggle("trayExpanded")
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

                Rectangle {
                    id: slot

                    required property SystemTrayItem modelData

                    width: root.horizontal ? 30 : Theme.barWidth - 8
                    height: root.horizontal ? Theme.barWidth - 8 : 30
                    radius: Config.radius
                    color: hover.hovered ? Colours.alpha(Colours.surfaceText, 0.08) : "transparent"

                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: Config.iconSize - 2
                        source: slot.modelData.icon
                        asynchronous: true
                    }

                    HoverHandler {
                        id: hover
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.LeftButton && !slot.modelData.onlyMenu)
                                slot.modelData.activate();
                            else if (mouse.button === Qt.MiddleButton)
                                slot.modelData.secondaryActivate();
                            else if (slot.modelData.hasMenu)
                                menuAnchor.open();
                        }
                    }

                    WheelHandler {
                        onWheel: e => slot.modelData.scroll(e.angleDelta.y, false)
                    }

                    Rectangle {
                        visible: hover.hovered && (slot.modelData.tooltipTitle || slot.modelData.title)
                        anchors.left: Theme.barTop || Theme.barRight ? undefined : parent.right
                        anchors.right: Theme.barRight ? parent.left : undefined
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        anchors.verticalCenter: Theme.barTop ? undefined : parent.verticalCenter
                        anchors.top: Theme.barTop ? parent.bottom : undefined
                        anchors.topMargin: 10
                        anchors.horizontalCenter: Theme.barTop ? parent.horizontalCenter : undefined
                        width: tip.implicitWidth + 16
                        height: tip.implicitHeight + 10
                        radius: 8
                        color: Colours.alpha(Colours.inverseSurface, 0.95)
                        z: 10

                        StyledText {
                            id: tip

                            anchors.centerIn: parent
                            text: slot.modelData.tooltipTitle || slot.modelData.title
                            color: Colours.inverseSurfaceText
                            font.pixelSize: Config.fontSize - 1
                        }
                    }

                    QsMenuAnchor {
                        id: menuAnchor

                        menu: slot.modelData.menu
                        anchor.item: slot
                        anchor.edges: Theme.barTop ? Edges.Bottom : Theme.barRight ? Edges.Left : Edges.Right
                        anchor.gravity: Theme.barTop ? Edges.Bottom : Theme.barRight ? Edges.Left : Edges.Right
                        anchor.margins.left: Theme.barTop || Theme.barRight ? 0 : 8
                        anchor.margins.right: Theme.barRight ? 8 : 0
                        anchor.margins.top: Theme.barTop ? 8 : 0
                    }
                }
            }
        }
    }
}
