import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../../config"
import "../../services"
import "../../components"

// The DBus menu of a tray item; submenus drill down behind a back row.
ColumnLayout {
    id: root

    property SystemTrayItem item: null
    property var path: []   // open submenu entries, innermost last
    readonly property var handle: path.length > 0 ? path[path.length - 1] : (item?.menu ?? null)
    readonly property int rows: opener.children.values.length

    width: 280
    spacing: 2

    onItemChanged: path = []

    QsMenuOpener {
        id: opener

        menu: root.handle
    }

    SectionLabel {
        text: root.path.length > 0 ? (root.path[root.path.length - 1].text || "Menu") : (root.item?.tooltipTitle || root.item?.title || root.item?.id || "Tray")
    }

    Clickable {
        visible: root.path.length > 0
        Layout.fillWidth: true
        implicitHeight: 32
        radius: Theme.radiusItem
        onClicked: root.path = root.path.slice(0, -1)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 10
            spacing: 8

            MaterialIcon {
                text: "chevron_left"
                font.pixelSize: Config.iconSize - 4
                color: Colours.surfaceVariantText
            }

            StyledText {
                Layout.fillWidth: true
                text: "Back"
                color: Colours.surfaceVariantText
            }
        }
    }

    Repeater {
        model: opener.children

        Clickable {
            id: row

            required property QsMenuEntry modelData
            readonly property bool separator: modelData.isSeparator
            readonly property bool checkable: modelData.buttonType !== QsMenuButtonType.None
            readonly property bool checked: modelData.checkState === Qt.Checked

            Layout.fillWidth: true
            implicitHeight: separator ? 9 : 34
            radius: Theme.radiusItem
            disabled: separator || !modelData.enabled
            opacity: separator || modelData.enabled ? 1 : 0.5

            onClicked: {
                if (modelData.hasChildren) {
                    root.path = [...root.path, modelData];
                } else {
                    modelData.triggered();
                    Requests.closePopouts();
                }
            }

            Rectangle {
                visible: row.separator
                anchors.verticalCenter: parent.verticalCenter
                x: 10
                width: parent.width - 20
                height: 1
                color: Colours.alpha(Colours.outlineVariant, 0.7)
            }

            RowLayout {
                visible: !row.separator
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 8
                spacing: 10

                IconImage {
                    visible: row.modelData.icon !== ""
                    implicitSize: Config.iconSize - 4
                    source: row.modelData.icon
                    asynchronous: true
                }

                StyledText {
                    Layout.fillWidth: true
                    text: row.modelData.text
                    elide: Text.ElideRight
                }

                MaterialIcon {
                    visible: row.checkable
                    text: row.modelData.buttonType === QsMenuButtonType.RadioButton ? (row.checked ? "radio_button_checked" : "radio_button_unchecked") : row.checked ? "check_box" : row.modelData.checkState === Qt.PartiallyChecked ? "indeterminate_check_box" : "check_box_outline_blank"
                    font.pixelSize: Config.iconSize - 3
                    color: row.checked ? Theme.accent : Colours.surfaceVariantText
                }

                MaterialIcon {
                    visible: row.modelData.hasChildren
                    text: "chevron_right"
                    font.pixelSize: Config.iconSize - 4
                    color: Colours.surfaceVariantText
                }
            }
        }
    }

    StyledText {
        visible: root.rows === 0
        Layout.fillWidth: true
        Layout.margins: 10
        text: "No actions"
        color: Colours.surfaceVariantText
        horizontalAlignment: Text.AlignHCenter
    }
}
