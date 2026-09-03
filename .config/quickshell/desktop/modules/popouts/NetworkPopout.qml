import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import "../../config"
import "../../services"
import "../../components"

ColumnLayout {
    id: root

    // VPN lives here too; past three connections only the active (or first)
    // stay inline and the rest fold, so the popout never grows into a strip
    readonly property bool foldVpn: Vpn.connections.length > 3
    readonly property list<var> vpnInline: !foldVpn ? Vpn.connections : Vpn.active.length > 0 ? Vpn.active : Vpn.connections.slice(0, 1)
    readonly property list<var> vpnRest: foldVpn ? Vpn.connections.filter(c => !vpnInline.includes(c)) : []
    property bool vpnOpen: false

    width: Config.popouts.width
    spacing: 6

    Component.onCompleted: {
        Net.setScanning(true);
        Net.refreshAddresses();
    }
    Component.onDestruction: Net.setScanning(false)

    ListItem {
        Layout.fillWidth: true
        visible: Net.wired !== null
        icon: "lan"
        title: "Wired"
        subtitle: Net.wired?.connected ? `Connected · ${Net.addressOf(Net.wired)}` + (Net.wired.linkSpeed ? ` · ${Net.wired.linkSpeed} Mb/s` : "") : Net.wired?.hasLink ? "Link up, not connected" : "No link"
        active: Net.wired?.connected ?? false
        accent: Colours.success
    }

    SectionLabel {
        text: "Wi-Fi"

        IconButton {
            visible: Net.wifi !== null && Net.wifiEnabled
            icon: "refresh"
            size: 26
            iconSize: Config.iconSize - 5
            onClicked: {
                Net.setScanning(false);
                Net.setScanning(true);
            }
        }

        Toggle {
            visible: Net.wifi !== null
            checked: Net.wifiEnabled
            onToggled: v => Networking.wifiEnabled = v
        }
    }

    StyledText {
        visible: Net.wifi === null
        text: "No Wi-Fi adapter"
        color: Colours.surfaceVariantText
    }

    ListView {
        id: list

        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(Config.popouts.listHeight, contentHeight)
        visible: Net.wifi !== null && Net.wifiEnabled
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: Net.wifiNetworks
        spacing: 2

        delegate: Column {
            id: entry

            required property var modelData

            width: list.width

            ListItem {
                width: parent.width
                icon: Net.signalIcon(modelData.signalStrength)
                title: modelData.name
                subtitle: modelData.connected ? "Connected" + (Net.addressOf(Net.wifi) ? ` · ${Net.addressOf(Net.wifi)}` : "") : modelData.stateChanging ? "Connecting…" : modelData.known ? "Saved" : Net.secured(modelData) ? "Secured · opens NetworkManager" : "Open"
                active: modelData.connected
                // No password prompt here: unknown secured networks are set up
                // in NetworkManager's own editor.
                onClicked: {
                    if (modelData.connected)
                        modelData.disconnect();
                    else if (modelData.known || !Net.secured(modelData))
                        modelData.connect();
                    else {
                        Quickshell.execDetached(["nm-connection-editor"]);
                        Requests.closePopouts();
                    }
                }

                MaterialIcon {
                    visible: Net.secured(entry.modelData)
                    text: "lock"
                    font.pixelSize: Config.iconSize - 6
                    color: Colours.surfaceVariantText
                }

                IconButton {
                    visible: entry.modelData.known && !entry.modelData.connected
                    icon: "delete"
                    size: 26
                    iconSize: Config.iconSize - 5
                    onClicked: entry.modelData.forget()
                }
            }
        }
    }
    SectionLabel {
        visible: Vpn.connections.length > 0
        text: "VPN"

        Chip {
            visible: Vpn.active.length > 1
            icon: "link_off"
            text: "Disconnect all"
            onClicked: Vpn.disconnectAll()
        }
    }

    component VpnRow: ListItem {
        id: vrow

        required property var modelData

        Layout.fillWidth: true
        icon: modelData.type === "wireguard" ? "shield" : "vpn_lock"
        title: modelData.name
        subtitle: modelData.active ? "Connected" + (modelData.device ? " · " + modelData.device : "") : modelData.type === "wireguard" ? "WireGuard" : "OpenVPN"
        active: modelData.active
        accent: Colours.success
        onClicked: Vpn.toggle(modelData)

        Toggle {
            checked: vrow.modelData.active
            onToggled: Vpn.toggle(vrow.modelData)
        }
    }

    Repeater {
        model: root.vpnInline

        VpnRow {}
    }

    DisclosureRow {
        visible: root.foldVpn
        icon: "more_horiz"
        title: root.vpnOpen ? "Fewer connections" : `${root.vpnRest.length} more`
        open: root.vpnOpen
        onClicked: root.vpnOpen = !root.vpnOpen
    }

    Collapsible {
        open: root.vpnOpen && root.foldVpn

        // dozens of provider endpoints are common: compact rows, six visible, scroll
        ListView {
            id: vpnList

            Layout.fillWidth: true
            implicitHeight: Math.min(count, 6) * 30
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.vpnRest
            spacing: 2

            delegate: Clickable {
                id: vrest

                required property var modelData

                width: ListView.view.width
                height: 30
                radius: Theme.radiusItem
                baseColor: modelData.active ? Theme.activeFill : "transparent"
                onClicked: Vpn.toggle(modelData)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    MaterialIcon {
                        text: vrest.modelData.type === "wireguard" ? "shield" : "vpn_lock"
                        font.pixelSize: Config.iconSize - 4
                        color: vrest.modelData.active ? Theme.activeIcon : Colours.surfaceVariantText
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: vrest.modelData.name
                        color: vrest.modelData.active ? Theme.activeText : Colours.surfaceText
                        font.pixelSize: Config.fontSize - 1
                    }

                    MaterialIcon {
                        visible: vrest.modelData.active
                        text: "check"
                        font.pixelSize: Config.iconSize - 4
                        color: Theme.activeIcon
                    }
                }
            }
        }
    }
}
