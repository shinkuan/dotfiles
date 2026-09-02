import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../../config"
import "../../services"
import "../../components"

Grid {
    id: root

    flow: Theme.barTop ? Grid.LeftToRight : Grid.TopToBottom
    columns: Theme.barTop ? 99 : 1
    spacing: 2
    visible: SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items

        Rectangle {
            id: slot

            required property SystemTrayItem modelData

            width: Theme.barTop ? 30 : Theme.barWidth - 8
            height: Theme.barTop ? Theme.barWidth - 8 : 30
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
