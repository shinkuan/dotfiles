import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import "../../config"
import "../../services"
import "../../components"

ColumnLayout {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property list<var> devices: Bluetooth.devices.values.filter(d => d.paired || d.bonded || adapter?.discovering).sort((a, b) => (b.connected - a.connected) || ((b.paired || b.bonded) - (a.paired || a.bonded)) || a.name.localeCompare(b.name))

    width: Config.popouts.width
    spacing: 6

    Component.onDestruction: {
        if (adapter)
            adapter.discovering = false;
    }

    function iconFor(dev: BluetoothDevice): string {
        const i = dev.icon ?? "";
        if (i.includes("headset") || i.includes("headphone"))
            return "headphones";
        if (i.includes("mouse"))
            return "mouse";
        if (i.includes("keyboard"))
            return "keyboard";
        if (i.includes("phone"))
            return "smartphone";
        if (i.includes("gaming") || i.includes("joystick"))
            return "sports_esports";
        if (i.includes("audio") || i.includes("speaker"))
            return "speaker";
        if (i.includes("watch"))
            return "watch";
        return "bluetooth";
    }

    SectionLabel {
        text: "Bluetooth"

        IconButton {
            visible: root.adapter?.enabled ?? false
            icon: "bluetooth_searching"
            checked: root.adapter?.discovering ?? false
            size: 26
            iconSize: Config.iconSize - 5
            onClicked: root.adapter.discovering = !root.adapter.discovering
        }

        Toggle {
            checked: root.adapter?.enabled ?? false
            onToggled: v => {
                if (root.adapter)
                    root.adapter.enabled = v;
            }
        }
    }

    StyledText {
        visible: root.adapter === null
        text: "No Bluetooth adapter"
        color: Colours.onSurfaceVariant
    }

    StyledText {
        visible: root.adapter !== null && root.devices.length === 0
        text: root.adapter?.enabled ? (root.adapter.discovering ? "Scanning…" : "No paired devices") : "Bluetooth is off"
        color: Colours.onSurfaceVariant
    }

    ListView {
        id: list

        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(Config.popouts.listHeight, contentHeight)
        visible: root.devices.length > 0
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.devices
        spacing: 2

        delegate: ListItem {
            id: entry

            required property BluetoothDevice modelData

            width: list.width
            icon: root.iconFor(modelData)
            title: modelData.name || modelData.deviceName || modelData.address
            subtitle: {
                if (modelData.state === BluetoothDeviceState.Connecting)
                    return "Connecting…";
                if (modelData.pairing)
                    return "Pairing…";
                if (modelData.connected)
                    return "Connected" + (modelData.batteryAvailable ? ` · ${Math.round(modelData.battery * 100)}%` : "");
                return modelData.paired || modelData.bonded ? "Paired" : "Available";
            }
            active: modelData.connected
            onClicked: {
                if (modelData.connected)
                    modelData.disconnect();
                else if (modelData.paired || modelData.bonded)
                    modelData.connect();
                else
                    modelData.pair();
            }

            MaterialIcon {
                visible: entry.modelData.connected && entry.modelData.batteryAvailable
                text: {
                    const level = Math.min(6, Math.round(entry.modelData.battery * 6));
                    return level === 6 ? "battery_full" : level === 0 ? "battery_alert" : `battery_${level}_bar`;
                }
                font.pixelSize: Config.iconSize - 4
                color: Colours.onSurfaceVariant
            }

            IconButton {
                visible: (entry.modelData.paired || entry.modelData.bonded) && !entry.modelData.connected
                icon: "delete"
                size: 26
                iconSize: Config.iconSize - 5
                onClicked: entry.modelData.forget()
            }
        }
    }
}
