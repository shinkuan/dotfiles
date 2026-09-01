import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"

// icon | title / subtitle | trailing
Clickable {
    id: root

    property string icon: ""
    property bool iconFill: false
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property color accent: Colours.primary
    default property alias trailing: trailingRow.data

    implicitHeight: 44
    implicitWidth: row.implicitWidth
    baseColor: active ? Colours.alpha(accent, 0.16) : "transparent"

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 10

        MaterialIcon {
            visible: root.icon !== ""
            text: root.icon
            fill: root.iconFill
            color: root.active ? root.accent : Colours.surfaceVariantText
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.title
                color: root.active ? root.accent : Colours.surfaceText
                font.weight: root.active ? Font.DemiBold : Font.Normal
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.subtitle !== ""
                text: root.subtitle
                color: Colours.surfaceVariantText
                font.pixelSize: Config.fontSize - 2
            }
        }

        Row {
            id: trailingRow

            spacing: 6
        }
    }
}
