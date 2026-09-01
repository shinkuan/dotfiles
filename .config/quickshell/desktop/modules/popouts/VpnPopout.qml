import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../components"

ColumnLayout {
    id: root

    property string filter: ""
    readonly property bool needsKeyboard: Vpn.connections.length > 8
    readonly property list<var> shown: Vpn.connections.filter(c => filter === "" || c.name.toLowerCase().includes(filter.toLowerCase()))

    width: Config.popouts.width
    spacing: 6

    SectionLabel {
        text: "VPN"

        Chip {
            visible: Vpn.active.length > 0
            icon: "link_off"
            text: "Disconnect all"
            onClicked: Vpn.disconnectAll()
        }
    }

    StyledText {
        visible: Vpn.connections.length === 0
        text: Vpn.available ? "No VPN connections configured" : "nmcli not available"
        color: Colours.surfaceVariantText
    }

    Rectangle {
        Layout.fillWidth: true
        visible: Vpn.connections.length > 8
        height: 34
        radius: Config.radius
        color: Colours.surfaceContainerHighest

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 6
            spacing: 6

            MaterialIcon {
                text: "search"
                font.pixelSize: Config.iconSize - 4
                color: Colours.surfaceVariantText
            }

            TextInput {
                id: input

                Layout.fillWidth: true
                color: Colours.surfaceText
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
                focus: true
                onTextChanged: root.filter = text

                StyledText {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    visible: !input.text
                    text: "Filter connections"
                    color: Colours.outline
                }
            }
        }
    }

    ListView {
        id: list

        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(Config.popouts.listHeight, contentHeight)
        visible: root.shown.length > 0
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.shown
        spacing: 2

        delegate: ListItem {
            id: entry

            required property var modelData

            width: list.width
            icon: modelData.type === "wireguard" ? "shield" : "vpn_lock"
            title: modelData.name
            subtitle: modelData.active ? "Connected" + (modelData.device ? " · " + modelData.device : "") : modelData.type === "wireguard" ? "WireGuard" : "OpenVPN"
            active: modelData.active
            accent: Colours.success
            onClicked: Vpn.toggle(modelData)

            Toggle {
                checked: entry.modelData.active
                onToggled: Vpn.toggle(entry.modelData)
            }
        }
    }
}
