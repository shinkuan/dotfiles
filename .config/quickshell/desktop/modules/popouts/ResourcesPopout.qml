import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../components"

ColumnLayout {
    id: root

    readonly property var rootDisk: Resources.disks.find(d => d.mount === "/") ?? Resources.disks[0] ?? null
    readonly property list<var> otherDisks: Resources.disks.filter(d => d.mount !== (rootDisk?.mount ?? ""))
    property bool disksOpen: false

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

        // only "/" by default; the other mounts fold out
        Clickable {
            visible: root.otherDisks.length > 0
            implicitWidth: moreRow.implicitWidth + 12
            implicitHeight: 18
            radius: 9
            onClicked: root.disksOpen = !root.disksOpen

            Row {
                id: moreRow

                anchors.centerIn: parent
                spacing: 2

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.disksOpen ? "less" : `+${root.otherDisks.length} more`
                    color: Theme.labelColor
                    font.family: Theme.fontLabel
                    font.pixelSize: Theme.labelSize
                    font.letterSpacing: Theme.labelSpacing
                }

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "expand_more"
                    font.pixelSize: Config.iconSize - 6
                    color: Theme.labelColor
                    rotation: root.disksOpen ? 180 : 0

                    Behavior on rotation {
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }

    Meter {
        visible: root.rootDisk !== null
        icon: "hard_drive"
        label: root.rootDisk?.mount ?? ""
        value: root.rootDisk ? `${Resources.fmtBytes(root.rootDisk.used, 0)} / ${Resources.fmtBytes(root.rootDisk.size, 0)}` : ""
        ratio: root.rootDisk && root.rootDisk.size > 0 ? root.rootDisk.used / root.rootDisk.size : 0
    }

    Collapsible {
        open: root.disksOpen

        Repeater {
            model: root.otherDisks

            Meter {
                required property var modelData

                spacing: 2
                icon: "hard_drive"
                label: modelData.mount
                value: `${Resources.fmtBytes(modelData.used, 0)} / ${Resources.fmtBytes(modelData.size, 0)}`
                ratio: modelData.size > 0 ? modelData.used / modelData.size : 0
            }
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
                color: Colours.surfaceVariantText
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
                color: Colours.surfaceVariantText
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
