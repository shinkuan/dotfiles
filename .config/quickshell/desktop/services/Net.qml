pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    id: root

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wired: Networking.devices.values.find(d => d.type === DeviceType.Wired && d.connected) ?? Networking.devices.values.find(d => d.type === DeviceType.Wired && d.hasLink) ?? Networking.devices.values.find(d => d.type === DeviceType.Wired) ?? null
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wiredConnected: wired?.connected ?? false
    readonly property var activeWifi: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property bool connected: wiredConnected || activeWifi !== null
    property bool scanning: false

    // strongest entry per SSID, connected first
    readonly property list<var> wifiNetworks: {
        if (!wifi)
            return [];
        const seen = {};
        const out = [];
        for (const n of wifi.networks.values) {
            if (!n.name)
                continue;
            const prev = seen[n.name];
            if (prev === undefined) {
                seen[n.name] = out.length;
                out.push(n);
            } else if (n.connected || (!out[prev].connected && n.signalStrength > out[prev].signalStrength)) {
                out[prev] = n;
            }
        }
        return out.sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength));
    }

    function signalIcon(strength: real): string {
        if (strength > 0.75)
            return "network_wifi";
        if (strength > 0.5)
            return "network_wifi_3_bar";
        if (strength > 0.25)
            return "network_wifi_2_bar";
        return "network_wifi_1_bar";
    }

    function secured(net): bool {
        return net && net.security !== WifiSecurityType.Open;
    }

    function setScanning(on: bool): void {
        if (wifi)
            wifi.scannerEnabled = on;
        scanning = on;
    }
}
