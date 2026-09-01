pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Low-battery warnings for laptops, once per threshold per discharge.
Singleton {
    id: root

    readonly property UPowerDevice device: UPower.displayDevice
    readonly property bool laptop: device?.isLaptopBattery ?? false
    readonly property int percent: Math.round((device?.percentage ?? 0) * 100)
    readonly property list<var> levels: [
        { level: 20, urgency: "normal", title: "Low battery", body: "20% left — consider plugging in." },
        { level: 10, urgency: "normal", title: "Battery getting low", body: "10% left — plug in soon." },
        { level: 5, urgency: "critical", title: "Critical battery", body: "5% left — plug in now." }
    ]
    property var warned: ({})

    onPercentChanged: check()

    Connections {
        target: UPower

        function onOnBatteryChanged(): void {
            if (!UPower.onBattery)
                root.warned = {};
            else
                root.check();
        }
    }

    function check(): void {
        if (!laptop || !UPower.onBattery)
            return;
        for (const w of levels) {
            if (percent <= w.level && !warned[w.level]) {
                warned = Object.assign({}, warned, { [w.level]: true });
                Quickshell.execDetached(["notify-send", "-a", "desktop-shell", "-i", "battery-caution", "-u", w.urgency, w.title, w.body]);
            }
        }
    }
}
