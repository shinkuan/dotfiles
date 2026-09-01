import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../../config"

ColumnLayout {
    id: root

    spacing: 6

    Repeater {
        model: SystemTray.items

        Item {
            id: slot

            required property SystemTrayItem modelData

            Layout.alignment: Qt.AlignHCenter
            implicitWidth: Config.iconSize
            implicitHeight: Config.iconSize

            IconImage {
                anchors.fill: parent
                source: slot.modelData.icon
                asynchronous: true
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

            QsMenuAnchor {
                id: menuAnchor

                menu: slot.modelData.menu
                anchor.item: slot
                anchor.edges: Edges.Right
                anchor.gravity: Edges.Right
            }
        }
    }
}
