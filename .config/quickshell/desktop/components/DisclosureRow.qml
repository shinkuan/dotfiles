import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"

// Compact row that toggles a Collapsible: icon | title | detail | chevron
Clickable {
    id: root

    property string icon: ""
    property string title: ""
    property string detail: ""
    property bool open: false

    Layout.fillWidth: true
    implicitHeight: 32
    radius: Theme.radiusItem

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 6
        spacing: 10

        MaterialIcon {
            visible: root.icon !== ""
            text: root.icon
            font.pixelSize: Config.iconSize - 4
            color: Colours.surfaceVariantText
        }

        StyledText {
            Layout.fillWidth: true
            text: root.title
            font.pixelSize: Config.fontSize - 1
        }

        StyledText {
            visible: root.detail !== ""
            text: root.detail
            color: Colours.surfaceVariantText
            font.family: Config.fontFamilyMono
            font.pixelSize: Config.fontSize - 2
        }

        MaterialIcon {
            text: "expand_more"
            font.pixelSize: Config.iconSize - 4
            color: Colours.surfaceVariantText
            rotation: root.open ? 180 : 0

            Behavior on rotation {
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
