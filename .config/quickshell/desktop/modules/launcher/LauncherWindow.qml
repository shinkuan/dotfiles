import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
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
        }
        return `Search apps  ·  ${Config.launcher.actionPrefix} actions  ·  ${Config.launcher.calcPrefix} calc  ·  ${Config.launcher.clipPrefix} clipboard`;
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Launcher.hide()
    }

    Rectangle {
        id: panel

        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.18)
        width: 640
        height: column.implicitHeight + 24
        radius: Config.radiusLarge
        color: Colours.surfaceContainer
        border.width: 1
        border.color: Colours.alpha(Colours.outlineVariant, 0.5)

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
                radius: Config.radius + 2
                color: Colours.surfaceContainerHighest

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10

                    MaterialIcon {
                        text: root.modeIcon()
                        color: Colours.primary
                    }

                    TextInput {
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
                            case Qt.Key_Tab:
                                Launcher.move(1);
                                break;
                            case Qt.Key_Up:
                            case Qt.Key_Backtab:
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

            ListView {
                id: list

                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(Config.launcher.maxResults, count) * (56 + spacing)
                visible: count > 0
                clip: true
                model: Launcher.results
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
                visible: list.count === 0 && Launcher.query !== ""
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                text: "No results"
                color: Colours.surfaceVariantText
            }
        }
    }
}
