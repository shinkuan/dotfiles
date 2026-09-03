import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../components"

DashTile {
    id: root

    RowLayout {
        anchors.fill: parent
        spacing: 18

        MaterialIcon {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 6
            text: Weather.ready && Weather.error === "" ? Weather.icon : "cloud_off"
            color: Weather.ready && Weather.error === "" ? Colours.surfaceText : Colours.surfaceVariantText
            font.pixelSize: 64
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            StyledText {
                visible: Weather.ready && Weather.error === ""
                text: Weather.temp
                font.family: Theme.fontLabel
                font.pixelSize: 40
                font.weight: Font.DemiBold
                lineHeight: 0.9
                lineHeightMode: Text.ProportionalHeight
            }

            StyledText {
                Layout.fillWidth: true
                text: Weather.ready && Weather.error === "" ? Weather.description : (Weather.error || "Loading…")
                font.pixelSize: Config.fontSize + 1
                color: Weather.ready && Weather.error === "" ? Colours.surfaceText : Colours.surfaceVariantText
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: Weather.ready && Weather.error === "" ? Weather.location : ""
                color: Colours.outline
                font.pixelSize: Config.fontSize - 2
                elide: Text.ElideRight
            }
        }
    }
}
