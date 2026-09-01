import QtQuick
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import "../../config"
import "../../services"
import "../../components"

Column {
    id: root

    readonly property list<var> bluetoothConnected: Bluetooth.devices.values.filter(d => d.connected)

    spacing: 0

    BarItem {
        popout: "audio"

        MaterialIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Audio.muted ? "volume_off" : Audio.volume > 0.5 ? "volume_up" : Audio.volume > 0 ? "volume_down" : "volume_mute"
            color: Audio.muted ? Colours.outline : Colours.surfaceText
        }

        WheelHandler {
            onWheel: e => Audio.increment(e.angleDelta.y > 0 ? 0.05 : -0.05)
        }

        onClicked: m => {
            if (m.button === Qt.MiddleButton)
                Audio.toggleMute(Audio.sink);
        }
    }

    BarItem {
        popout: "audio"

        MaterialIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Audio.sourceMuted ? "mic_off" : "mic"
            color: Audio.sourceMuted ? Colours.outline : Colours.surfaceText
        }

        onClicked: m => {
            if (m.button === Qt.MiddleButton)
                Audio.toggleMute(Audio.source);
        }
    }

    BarItem {
        popout: "network"

        MaterialIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Net.wiredConnected ? "lan" : Net.activeWifi ? Net.signalIcon(Net.activeWifi.signalStrength) : Net.wifiEnabled ? "signal_wifi_0_bar" : "signal_wifi_off"
            color: Net.connected ? Colours.surfaceText : Colours.outline
        }
    }

    BarItem {
        popout: "vpn"
        visible: Vpn.connections.length > 0

        MaterialIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Vpn.active.length > 0 ? "vpn_lock" : "vpn_key_off"
            color: Vpn.active.length > 0 ? Colours.primary : Colours.outline
        }
    }

    BarItem {
        popout: "bluetooth"
        visible: Bluetooth.defaultAdapter !== null

        MaterialIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.bluetoothConnected.length > 0 ? "bluetooth_connected" : "bluetooth"
            color: !(Bluetooth.defaultAdapter?.enabled ?? false) ? Colours.outline : root.bluetoothConnected.length > 0 ? Colours.primary : Colours.surfaceText
        }
    }

    BarItem {
        popout: "power"
        visible: UPower.displayDevice?.isLaptopBattery ?? false
        spacing: 0

        MaterialIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            text: {
                const p = UPower.displayDevice?.percentage ?? 0;
                if (!UPower.onBattery)
                    return "battery_charging_full";
                const level = Math.min(6, Math.round(p * 6));
                return level === 6 ? "battery_full" : level === 0 ? "battery_alert" : `battery_${level}_bar`;
            }
            color: (UPower.displayDevice?.percentage ?? 1) < 0.15 && UPower.onBattery ? Colours.error : Colours.surfaceText
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Math.round((UPower.displayDevice?.percentage ?? 0) * 100) + "%"
            color: Colours.surfaceVariantText
            font.pixelSize: Config.fontSize - 4
        }
    }
}
