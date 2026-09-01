import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../components"

ColumnLayout {
    id: root

    width: Config.popouts.width
    spacing: 10

    Component.onCompleted: Resources.watchers++
    Component.onDestruction: Resources.watchers--

    SectionLabel {
        text: "System"
    }

    Meter {
        icon: "memory"
        label: "CPU"
        value: `${Math.round(Resources.cpu * 100)}%` + (Resources.cpuTemp > 0 ? `  ${Math.round(Resources.cpuTemp)}°C` : "")
        ratio: Resources.cpu
    }

    Meter {
        icon: "database"
        label: "Memory"
        value: `${Resources.fmtBytes(Resources.memUsed)} / ${Resources.fmtBytes(Resources.memTotal)}`
        ratio: Resources.memRatio
    }

    Meter {
        visible: Resources.swapTotal > 0
        icon: "swap_horiz"
        label: "Swap"
        value: `${Resources.fmtBytes(Resources.swapUsed)} / ${Resources.fmtBytes(Resources.swapTotal)}`
        ratio: Resources.swapTotal > 0 ? Resources.swapUsed / Resources.swapTotal : 0
    }

    Meter {
        visible: Resources.gpu !== null && Resources.gpu !== undefined
        icon: "developer_board"
        label: "GPU"
        value: Resources.gpu ? `${Math.round(Resources.gpu.util * 100)}%  ${Math.round(Resources.gpu.temp)}°C` : ""
        ratio: Resources.gpu?.util ?? 0
    }

    Meter {
        visible: Resources.gpu !== null && Resources.gpu !== undefined
        icon: "view_in_ar"
        label: "VRAM"
        value: Resources.gpu ? `${Resources.fmtBytes(Resources.gpu.memUsed)} / ${Resources.fmtBytes(Resources.gpu.memTotal)}` : ""
        ratio: Resources.gpu ? Resources.gpu.memUsed / Resources.gpu.memTotal : 0
    }

    SectionLabel {
        visible: Resources.disks.length > 0
        text: "Storage"
    }

    Repeater {
        model: Resources.disks

        Meter {
            required property var modelData

            icon: "hard_drive"
            label: modelData.mount
            value: `${Resources.fmtBytes(modelData.used, 0)} / ${Resources.fmtBytes(modelData.size, 0)}`
            ratio: modelData.size > 0 ? modelData.used / modelData.size : 0
        }
    }

    SectionLabel {
        text: "Network"
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 16

        RowLayout {
            spacing: 6

            MaterialIcon {
                text: "download"
                font.pixelSize: Config.iconSize - 3
                color: Colours.onSurfaceVariant
            }

            StyledText {
                text: Resources.fmtBytes(Resources.netRx) + "/s"
                font.family: Config.fontFamilyMono
            }
        }

        RowLayout {
            spacing: 6

            MaterialIcon {
                text: "upload"
                font.pixelSize: Config.iconSize - 3
                color: Colours.onSurfaceVariant
            }

            StyledText {
                text: Resources.fmtBytes(Resources.netTx) + "/s"
                font.family: Config.fontFamilyMono
            }
        }

        Item {
            Layout.fillWidth: true
        }
    }
}
