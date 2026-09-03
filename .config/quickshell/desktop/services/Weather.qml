pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

// Current conditions from wttr.in (JSON). Never blocks the UI: a failed
// fetch leaves `error` set and the tile shows "unavailable".
Singleton {
    id: root

    property bool ready: false
    property string error: ""
    property string temp: ""
    property string description: ""
    property string icon: "cloud"
    property string location: ""
    property real lastFetch: 0

    readonly property string unit: (Config.weather.unit || "c").toLowerCase() === "f" ? "F" : "C"
    readonly property string url: `https://wttr.in/${encodeURIComponent(Config.weather.location || "")}?format=j1`

    function refresh(force: bool): void {
        if (fetch.running)
            return;
        if (!force && Date.now() - lastFetch < 5 * 60 * 1000)
            return;
        fetch.running = true;
    }

    // WWO weather codes -> Material Symbols
    function iconFor(code: int, night: bool): string {
        if (code === 113)
            return night ? "clear_night" : "sunny";
        if (code === 116)
            return night ? "partly_cloudy_night" : "partly_cloudy_day";
        if (code === 119 || code === 122)
            return "cloud";
        if ([143, 248, 260].includes(code))
            return "foggy";
        if ([200, 386, 389, 392, 395].includes(code))
            return "thunderstorm";
        if ([179, 227, 230, 323, 326, 329, 332, 335, 338, 368, 371].includes(code))
            return "weather_snowy";
        if ([182, 185, 281, 284, 311, 314, 317, 320, 350, 362, 365, 374, 377].includes(code))
            return "weather_mix";
        if ([176, 263, 266, 293, 296, 299, 302, 305, 308, 353, 356, 359].includes(code))
            return "rainy";
        return "cloud";
    }

    function minutesOf(t: string): int {
        // "05:34 AM"
        const m = t.trim().match(/^(\d{1,2}):(\d{2})\s*([AP]M)?$/i);
        if (!m)
            return -1;
        let h = parseInt(m[1], 10);
        const ampm = (m[3] || "").toUpperCase();
        if (ampm === "PM" && h < 12)
            h += 12;
        if (ampm === "AM" && h === 12)
            h = 0;
        return h * 60 + parseInt(m[2], 10);
    }

    function parse(text: string): void {
        let d;
        try {
            d = JSON.parse(text);
        } catch (e) {
            error = "Weather unavailable";
            return;
        }
        const c = d.current_condition?.[0];
        if (!c) {
            error = "Weather unavailable";
            return;
        }
        const now = new Date();
        const mins = now.getHours() * 60 + now.getMinutes();
        const astro = d.weather?.[0]?.astronomy?.[0];
        const rise = astro ? minutesOf(astro.sunrise) : -1;
        const set = astro ? minutesOf(astro.sunset) : -1;
        const night = rise >= 0 && set >= 0 ? (mins < rise || mins >= set) : (mins < 6 * 60 || mins >= 18 * 60);
        temp = `${unit === "F" ? c.temp_F : c.temp_C}°${unit}`;
        description = c.weatherDesc?.[0]?.value ?? "";
        icon = iconFor(parseInt(c.weatherCode, 10), night);
        location = d.nearest_area?.[0]?.areaName?.[0]?.value ?? "";
        lastFetch = Date.now();
        error = "";
        ready = true;
    }

    Process {
        id: fetch

        command: ["curl", "-sf", "--max-time", "10", root.url]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length > 0)
                    root.parse(text);
            }
        }
        onExited: (code, status) => {
            if (code !== 0)
                root.error = "Weather unavailable";
        }
    }

    Timer {
        interval: Math.max(5, Config.weather.refreshMinutes) * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refresh(true)
    }

    Connections {
        target: Config.weather

        function onLocationChanged(): void {
            root.refresh(true);
        }

        function onUnitChanged(): void {
            root.refresh(true);
        }
    }

    Component.onCompleted: refresh(true)
}
