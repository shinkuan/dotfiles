import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../components"

// CPU / memory / GPU as three rings.
DashTile {
    id: root

    property bool active: false

    onActiveChanged: Resources.watchers += active ? 1 : -1
    Component.onDestruction: {
        if (active)
            Resources.watchers--;
    }

    RowLayout {
        anchors.fill: parent
        spacing: 8

        Gauge {
            icon: "memory"
            value: Resources.cpu
            label: `${Math.round(Resources.cpu * 100)}%`
            sub: Resources.cpuTemp > 0 ? `${Math.round(Resources.cpuTemp)}°C` : ""
            fill: Theme.accent
        }

        Gauge {
            icon: "developer_board"
            value: Resources.memRatio
            label: `${Math.round(Resources.memRatio * 100)}%`
            sub: Resources.memTotal > 0 ? `${(Resources.memUsed / 1073741824).toFixed(0)}G / ${(Resources.memTotal / 1073741824).toFixed(0)}G` : ""
            fill: Colours.tertiary
        }

        Gauge {
            icon: "videogame_asset"
            value: Resources.gpu ? Resources.gpu.util : 0
            label: Resources.gpu ? `${Math.round(Resources.gpu.util * 100)}%` : "–"
            sub: Resources.gpu && Resources.gpu.temp > 0 ? `${Math.round(Resources.gpu.temp)}°C` : ""
            fill: Colours.secondary
        }
    }

    component Gauge: ColumnLayout {
        id: gauge

        property string icon
        property real value: 0
        property string label
        property string sub
        property color fill: Theme.accent

        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        spacing: 4

        Ring {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 78
            implicitHeight: 78
            value: gauge.value
            fill: gauge.fill
            thickness: 6

            MaterialIcon {
                anchors.centerIn: parent
                text: gauge.icon
                color: Colours.surfaceText
                font.pixelSize: Config.iconSize + 6
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: gauge.label
            font.family: Config.fontFamilyMono
            font.pixelSize: Config.fontSize
            font.weight: Font.DemiBold
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            visible: text !== ""
            text: gauge.sub
            font.family: Config.fontFamilyMono
            font.pixelSize: Config.fontSize - 3
            color: Colours.surfaceVariantText
        }
    }
}
