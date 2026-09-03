import QtQuick
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import "../../config"
import "../../services"
import "../../components"

Grid {
    id: root

    readonly property list<var> bluetoothConnected: Bluetooth.devices.values.filter(d => d.connected)

    flow: Theme.barTop ? Grid.LeftToRight : Grid.TopToBottom
    columns: Theme.barTop ? 99 : 1
    spacing: 0

    BarItem {
        id: audioItem

        popout: "audio"

        MaterialIcon {
            text: Audio.muted ? "volume_off" : Audio.volume > 0.5 ? "volume_up" : Audio.volume > 0 ? "volume_down" : "volume_mute"
            color: Audio.muted ? audioItem.fgDim : audioItem.fg
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
        id: netItem

        popout: "network"

        MaterialIcon {
            text: Net.wiredConnected ? "lan" : Net.activeWifi ? Net.signalIcon(Net.activeWifi.signalStrength) : Net.wifiEnabled ? "signal_wifi_0_bar" : "signal_wifi_off"
            color: Net.connected ? netItem.fg : netItem.fgDim
        }
    }

    BarItem {
        id: vpnItem

        popout: "vpn"
        visible: Vpn.connections.length > 0

        MaterialIcon {
            text: Vpn.active.length > 0 ? "vpn_lock" : "vpn_key_off"
            color: Vpn.active.length > 0 ? vpnItem.fgAccent : vpnItem.fgDim
        }
    }

    BarItem {
        id: btItem

        popout: "bluetooth"
        visible: Bluetooth.defaultAdapter !== null

        MaterialIcon {
            text: root.bluetoothConnected.length > 0 ? "bluetooth_connected" : "bluetooth"
            color: !(Bluetooth.defaultAdapter?.enabled ?? false) ? btItem.fgDim : root.bluetoothConnected.length > 0 ? btItem.fgAccent : btItem.fg
        }
    }

    BarItem {
        id: batteryItem

        popout: "power"
        visible: UPower.displayDevice?.isLaptopBattery ?? false
        spacing: 0

        MaterialIcon {
            text: {
                const p = UPower.displayDevice?.percentage ?? 0;
                if (!UPower.onBattery)
                    return "battery_charging_full";
                const level = Math.min(6, Math.round(p * 6));
                return level === 6 ? "battery_full" : level === 0 ? "battery_alert" : `battery_${level}_bar`;
            }
            color: (UPower.displayDevice?.percentage ?? 1) < 0.15 && UPower.onBattery ? Colours.error : batteryItem.fg
        }

        StyledText {
            text: Math.round((UPower.displayDevice?.percentage ?? 0) * 100) + "%"
            color: batteryItem.filled ? batteryItem.fgDim : Colours.surfaceVariantText
            font.pixelSize: Config.fontSize - 4
        }
    }
}
