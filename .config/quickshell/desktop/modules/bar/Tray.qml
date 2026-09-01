import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../../config"
import "../../services"
import "../../components"

Column {
    id: root

    spacing: 2
    visible: SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items

        Rectangle {
            id: slot

            required property SystemTrayItem modelData

            width: Config.barWidth - 8
            height: 30
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
                anchors.left: parent.right
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
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
                anchor.edges: Edges.Right
                anchor.gravity: Edges.Right
                anchor.margins.left: 8
            }
        }
    }
}
