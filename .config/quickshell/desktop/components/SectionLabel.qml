import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"

// Section heading; Ledger rules it, Signal marks it, the rest set it in the
// theme's label face.
ColumnLayout {
    id: root

    property alias text: label.text
    default property alias trailing: trailing.data

    spacing: 4
    Layout.fillWidth: true
    Layout.topMargin: Theme.labelRuled ? 4 : 0

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
            visible: Theme.labelMarker
            width: 5
            height: 5
            color: Theme.labelColor
        }

        StyledText {
            id: label

            Layout.fillWidth: true
            color: Theme.labelColor
            font.family: Theme.fontLabel
            font.pixelSize: Theme.labelSize
            font.weight: Theme.labelWeight
            font.capitalization: Theme.labelUpper ? Font.AllUppercase : Font.MixedCase
            font.letterSpacing: Theme.labelSpacing
        }

        Row {
            id: trailing

            spacing: 4
        }
    }

    Rectangle {
        visible: Theme.labelRuled
        Layout.fillWidth: true
        height: Theme.labelRuleWidth
        color: Theme.labelRuleColor
    }
}
