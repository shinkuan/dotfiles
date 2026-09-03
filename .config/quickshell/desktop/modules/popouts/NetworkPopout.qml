import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import "../../config"
import "../../services"
import "../../components"

ColumnLayout {
    id: root

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
}
