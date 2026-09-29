import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../components"

// CPU / memory / GPU as three small rings with the numbers beside them.
DashTile {
    id: root

    property bool active: false

    onActiveChanged: Resources.watchers += active ? 1 : -1
    Component.onDestruction: {
        if (active)
            Resources.watchers--;
    }

    // Layouts round to whole logical px; at 1.5x an odd one is a half device
    // pixel, where NativeRendering drops a glyph column (a broken "/"). Even
    // gauge widths and no leftover space keep every gauge on an even x.
    RowLayout {
        readonly property int gaugeWidth: 2 * Math.floor((parent.width - spacing * 2) / 6)

        width: gaugeWidth * 3 + spacing * 2
        height: parent.height
        spacing: 4

        Gauge {
            icon: "memory"
            value: Resources.cpu
            label: `${Math.round(Resources.cpu * 100)}%`
            sub: Resources.cpuTemp > 0 ? `CPU ${Math.round(Resources.cpuTemp)}°` : "CPU"
        }

        Gauge {
            icon: "developer_board"
            value: Resources.memRatio
            label: `${Math.round(Resources.memRatio * 100)}%`
            sub: Resources.memTotal > 0 ? `${(Resources.memUsed / 1073741824).toFixed(0)}/${(Resources.memTotal / 1073741824).toFixed(0)} G` : "MEM"
        }

        Gauge {
            icon: "videogame_asset"
            value: Resources.gpu ? Resources.gpu.util : 0
            label: Resources.gpu ? `${Math.round(Resources.gpu.util * 100)}%` : "–"
            sub: Resources.gpu && Resources.gpu.memTotal > 0 ? `${(Resources.gpu.memUsed / 1073741824).toFixed(Resources.gpu.memUsed < 10 * 1073741824 ? 1 : 0)}/${(Resources.gpu.memTotal / 1073741824).toFixed(0)} G` : "GPU"
        }
    }

    component Gauge: RowLayout {
        id: gauge

        property string icon
        property real value: 0
        property string label
        property string sub

        Layout.preferredWidth: parent?.gaugeWidth ?? 0
        Layout.alignment: Qt.AlignVCenter
        spacing: 10

        Ring {
            implicitWidth: 48
            implicitHeight: 48
            value: gauge.value
            fill: Theme.accent
            thickness: 5

            MaterialIcon {
                anchors.centerIn: parent
                text: gauge.icon
                color: Colours.surfaceVariantText
                font.pixelSize: Config.iconSize - 3
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            StyledText {
                text: gauge.label
                font.pixelSize: Config.fontSize + 1
                font.weight: Font.DemiBold
            }

            StyledText {
                text: gauge.sub
                font.family: Config.fontFamilyMono
                font.pixelSize: Config.fontSize - 3
                color: Colours.surfaceVariantText
            }
        }
    }
}
