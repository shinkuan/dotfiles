import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import "../../config"
import "../../services"
import "../../components"

// Full-screen overlay on the focused monitor; click outside closes.
PanelWindow {
    id: root

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
    readonly property bool active: Launcher.open && (monitor?.focused ?? false)

    visible: active
    WlrLayershell.namespace: "desktop-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: Colours.alpha(Colours.scrim, 0.25)

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    onActiveChanged: {
        if (active)
            input.forceActiveFocus();
    }

    function modeIcon(): string {
        switch (Launcher.mode) {
        case "actions":
            return "bolt";
        case "calc":
            return "calculate";
        case "clip":
            return "content_paste";
        case "scheme":
            return "palette";
        case "variant":
            return "colors";
        case "wallpaper":
            return "image";
        case "emoji":
            return "mood";
        }
        return "search";
    }

    function placeholder(): string {
        switch (Launcher.mode) {
        case "actions":
            return "Actions";
        case "calc":
            return "Calculate";
        case "clip":
            return "Clipboard history";
        case "scheme":
            return "Colour scheme";
        case "variant":
            return "Scheme variant";
        case "wallpaper":
            return "Wallpaper";
        case "emoji":
            return "Emoji";
        }
        return `Search apps  ·  ${Config.launcher.actionPrefix} actions  ·  ${Config.launcher.calcPrefix} calc  ·  ${Config.launcher.clipPrefix} clipboard`;
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Launcher.hide()
    }

    Surface {
        id: panel

        anchors.horizontalCenter: parent.horizontalCenter
        y: Config.launcher.position === "center" ? Math.round((parent.height - height) / 2) : Math.round(parent.height * 0.18)
        width: 640
        height: column.implicitHeight + 24

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: column

            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                height: 48
                radius: Theme.capsule ? 24 : Theme.outlined ? 0 : Theme.radiusItem + 2
                color: Theme.outlined ? "transparent" : Theme.field

                // Ledger / Signal: the field is a ruled line, not a box
                Rectangle {
                    visible: Theme.outlined
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: Theme.signal ? Colours.alpha(Theme.accent, 0.4) : Colours.outlineVariant
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10

                    MaterialIcon {
                        text: root.modeIcon()
                        color: Theme.accent
                    }

                    TextInput {

                        renderType: Text.NativeRendering
                        id: input

                        Layout.fillWidth: true
                        color: Colours.surfaceText
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSize + 3
                        text: Launcher.query
                        onTextChanged: Launcher.query = text
                        Keys.onPressed: event => {
                            switch (event.key) {
                            case Qt.Key_Escape:
                                Launcher.hide();
                                break;
                            case Qt.Key_Down:
                                Launcher.move(Launcher.columns);
                                break;
                            case Qt.Key_Up:
                                Launcher.move(-Launcher.columns);
                                break;
                            case Qt.Key_Tab:
                            case Qt.Key_Right:
                                if (event.key === Qt.Key_Right && Launcher.columns === 1)
                                    return;
                                Launcher.move(1);
                                break;
                            case Qt.Key_Backtab:
                            case Qt.Key_Left:
                                if (event.key === Qt.Key_Left && Launcher.columns === 1)
                                    return;
                                Launcher.move(-1);
                                break;
                            case Qt.Key_Return:
                            case Qt.Key_Enter:
                                Launcher.activate(Launcher.selected);
                                break;
                            default:
                                return;
                            }
                            event.accepted = true;
                        }

                        StyledText {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            visible: !input.text
                            text: root.placeholder()
                            color: Colours.outline
                            font.pixelSize: Config.fontSize + 1
                        }
                    }
                }
            }

            // wallpaper picker: a thumbnail grid instead of rows
            GridView {
                id: grid

                readonly property int cols: Launcher.columns
                readonly property int cell: Math.floor(width / cols)

                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(3, Math.ceil(count / cols)) * cellHeight
                visible: Launcher.columns > 1 && count > 0
                clip: true
                model: Launcher.columns > 1 ? Launcher.results : []
                cellWidth: cell
                cellHeight: Math.round(cell * 9 / 16) + 30
                currentIndex: Launcher.selected
                boundsBehavior: Flickable.StopAtBounds
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)

                delegate: Item {
                    id: tile

                    required property var modelData
                    required property int index
                    readonly property bool selected: Launcher.selected === index

                    width: grid.cellWidth
                    height: grid.cellHeight

                    HoverHandler {
                        onHoveredChanged: {
                            if (hovered)
                                Launcher.selected = tile.index;
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Launcher.activate(tile.index)
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: Theme.radiusItem
                        color: tile.selected ? Theme.activeFill : "transparent"
                        border.width: tile.selected ? 2 : 0
                        border.color: Theme.accent
                    }

                    ClippingRectangle {
                        x: 8
                        y: 8
                        width: parent.width - 16
                        height: Math.round(width * 9 / 16)
                        radius: Math.max(0, Theme.radiusItem - 2)
                        color: Colours.surfaceContainerHighest

                        Image {
                            anchors.fill: parent
                            source: tile.modelData.thumb ? "file://" + tile.modelData.thumb : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize: Qt.size(320, 180)
                        }
                    }

                    StyledText {
                        x: 8
                        y: Math.round((parent.width - 16) * 9 / 16) + 12
                        width: parent.width - 16
                        text: tile.modelData.title
                        color: tile.selected ? Theme.activeText : Colours.surfaceVariantText
                        font.pixelSize: Config.fontSize - 2
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            ListView {
                id: list

                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(Config.launcher.maxResults, count) * (56 + spacing)
                visible: Launcher.columns === 1 && count > 0
                clip: true
                model: Launcher.columns === 1 ? Launcher.results : []
                spacing: 2
                currentIndex: Launcher.selected
                highlightMoveDuration: 0
                boundsBehavior: Flickable.StopAtBounds
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                delegate: LauncherRow {
                    required property var modelData
                    required property int index

                    width: list.width
                    entry: modelData
                    rowIndex: index
                }
            }

            StyledText {
                visible: Launcher.results.length === 0 && Launcher.query !== ""
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                text: "No results"
                color: Colours.surfaceVariantText
            }
        }
    }
}
