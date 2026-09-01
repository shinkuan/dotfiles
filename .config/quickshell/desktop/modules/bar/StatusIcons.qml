import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import "../../config"
import "../../services"

ColumnLayout {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property var wired: Networking.devices.values.find(d => d.type === DeviceType.Wired && d.connected)
    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi && d.connected)
    readonly property var bluetoothConnected: Bluetooth.devices.values.filter(d => d.connected)

    spacing: 6

    PwObjectTracker {
        objects: [root.sink, root.source].filter(n => n !== null)
    }

    StatusIcon {
        icon: {
            if (!root.sink?.audio || root.sink.audio.muted)
                return "volume_off";
            return root.sink.audio.volume > 0.5 ? "volume_up" : "volume_down";
        }
        dim: !root.sink?.audio || root.sink.audio.muted
    }

    StatusIcon {
        icon: root.source?.audio?.muted ?? true ? "mic_off" : "mic"
        dim: root.source?.audio?.muted ?? true
    }

    StatusIcon {
        icon: root.wired ? "lan" : root.wifi ? "wifi" : "signal_wifi_off"
        dim: !root.wired && !root.wifi
    }

    StatusIcon {
        icon: root.bluetoothConnected.length > 0 ? "bluetooth_connected" : "bluetooth"
        dim: !(Bluetooth.defaultAdapter?.enabled ?? false)
        visible: Bluetooth.defaultAdapter !== null
    }

    ColumnLayout {
        spacing: 0
        visible: UPower.displayDevice?.isLaptopBattery ?? false

        StatusIcon {
            Layout.alignment: Qt.AlignHCenter
            icon: UPower.onBattery ? "battery_5_bar" : "battery_charging_full"
            dim: false
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Math.round((UPower.displayDevice?.percentage ?? 0) * 100) + "%"
            color: Colours.onSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSize - 4
        }
    }

    component StatusIcon: Text {
        property string icon
        property bool dim: false

        Layout.alignment: Qt.AlignHCenter
        text: icon
        color: dim ? Colours.outline : Colours.onSurface
        font.family: Config.iconFont
        font.pixelSize: Config.iconSize
    }
}
