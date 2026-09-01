import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"

RowLayout {
    id: root

    property alias text: label.text
    default property alias trailing: trailing.data

    spacing: 8
    Layout.fillWidth: true

    StyledText {
        id: label

        Layout.fillWidth: true
        color: Colours.primary
        font.pixelSize: Config.fontSize - 1
        font.weight: Font.DemiBold
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1
    }

    Row {
        id: trailing

        spacing: 4
    }
}
