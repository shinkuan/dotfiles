import QtQuick
import "../../config"
import "../../services"
import "../../components"

// Two thin vertical meters: CPU and memory.
BarItem {
    id: root

    popout: "resources"

    Row {
        anchors.horizontalCenter: Theme.barTop ? undefined : parent.horizontalCenter
        anchors.verticalCenter: Theme.barTop ? parent.verticalCenter : undefined
        spacing: 4

        Repeater {
            model: [
                { icon: "memory", ratio: Resources.cpu },
                { icon: "database", ratio: Resources.memRatio }
            ]

            Rectangle {
                required property var modelData

                width: 6
                height: 28
                radius: 3
                color: Colours.surfaceContainerHighest

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: parent.height * Math.max(0.06, Math.min(1, parent.modelData.ratio))
                    radius: parent.radius
                    color: parent.modelData.ratio > 0.9 ? Colours.error : Theme.accent

                    Behavior on height {
                        NumberAnimation {
                            duration: Config.animDuration
                        }
                    }
                }
            }
        }
    }
}
