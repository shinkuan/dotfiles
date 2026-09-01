import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../../config"
import "../../services"
import "../../components"

Rectangle {
    id: root

    required property var entry
    property int rowIndex: -1
    readonly property bool selected: Launcher.selected === rowIndex
    readonly property bool danger: entry.danger === true

    height: 56
    radius: Config.radius
    color: selected ? Colours.alpha(danger ? Colours.error : Colours.primary, 0.18) : "transparent"

    HoverHandler {
        onHoveredChanged: {
            if (hovered)
                Launcher.selected = root.rowIndex;
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: Launcher.activate(root.rowIndex)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        Item {
            Layout.preferredWidth: root.entry.thumb || root.entry.image ? 72 : 32
            Layout.preferredHeight: 40

            IconImage {
                visible: root.entry.iconSource !== undefined
                anchors.centerIn: parent
                implicitSize: 30
                source: root.entry.iconSource ?? ""
                asynchronous: true
            }

            MaterialIcon {
                visible: root.entry.icon !== undefined && !(root.entry.image && thumb.status === Image.Ready)
                anchors.centerIn: parent
                text: root.entry.icon ?? ""
                color: root.danger ? Colours.error : root.selected ? Colours.primary : Colours.surfaceVariantText
                font.pixelSize: Config.iconSize + 3
            }

            ClippingRectangle {
                anchors.fill: parent
                visible: thumb.status === Image.Ready
                radius: 6
                color: "transparent"

                Image {
                    id: thumb

                    anchors.fill: parent
                    source: root.entry.thumb ? "file://" + root.entry.thumb : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize: Qt.size(144, 80)
                }
            }

            // clipboard images are decoded once into the cache dir
            Process {
                id: decode

                running: root.entry.image === true
                command: ["sh", "-c", '[ -s "$1" ] || cliphist decode "$2" > "$1"; echo "$1"', "_", `${Launcher.cacheDir}/${root.entry.clipId}.img`, root.entry.clipId]
                stdout: StdioCollector {
                    onStreamFinished: thumb.source = "file://" + text.trim()
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.entry.title
                color: root.danger ? Colours.error : Colours.surfaceText
                font.pixelSize: Config.fontSize + 1
                font.weight: root.selected ? Font.DemiBold : Font.Normal
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.entry.subtitle ?? ""
                color: Colours.surfaceVariantText
                font.pixelSize: Config.fontSize - 1
            }
        }

        IconButton {
            visible: root.entry.kind === "clip" && root.selected
            icon: "delete"
            size: 28
            iconSize: Config.iconSize - 4
            onClicked: Launcher.deleteClip(root.entry.clipLine)
        }

        StyledText {
            visible: root.entry.hint !== "" && root.selected
            text: root.entry.hint
            color: Colours.surfaceVariantText
            font.pixelSize: Config.fontSize - 2
        }
    }
}
