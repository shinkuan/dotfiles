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
    property color accent: Theme.accent
    default property alias trailing: trailingRow.data

    implicitHeight: Theme.ledger ? 38 : 44
    implicitWidth: row.implicitWidth
    radius: active && Theme.activePill ? height / 2 : Theme.radiusItem
    baseColor: active ? ((Theme.capsule || Theme.poster) ? Theme.activeFill : Theme.ledger ? "transparent" : Colours.alpha(accent, Theme.rim ? 0.11 : Theme.signal ? 0.12 : 0.16)) : "transparent"

    // Rim / Ledger: indicator rule on the left; Ledger: dashed row dividers
    Rectangle {
        visible: root.active && Theme.activeBar
        x: 0
        y: Theme.ledger ? 4 : 6
        width: 2
        height: parent.height - y * 2
        radius: 1
        color: root.accent
    }

    Rectangle {
        visible: Theme.ruledRows
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Colours.alpha(Colours.outlineVariant, 0.5)
    }

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
            color: root.active ? Theme.activeIcon : Colours.surfaceVariantText
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.title
                color: root.active ? Theme.activeText : Colours.surfaceText
                font.weight: root.active ? (Theme.ledger ? Font.Medium : Font.DemiBold) : Font.Normal
                font.underline: root.active && Theme.activeUnderline
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.subtitle !== ""
                text: root.subtitle
                color: root.active && Theme.poster ? Colours.alpha(Theme.activeText, 0.8) : Colours.surfaceVariantText
                font.pixelSize: Config.fontSize - 2
            }
        }

        Row {
            id: trailingRow

            spacing: 6
        }
    }
}
