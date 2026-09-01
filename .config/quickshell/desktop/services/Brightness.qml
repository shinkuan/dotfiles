pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../config"

// Per-output brightness: internal panels via brightnessctl, external displays
// via ddcutil (DDC/CI). Both are probed at startup; failures are reported
// instead of silently leaving the OSD dead.
Singleton {
    id: root

    // [{ name, value (0..1), kind: "ddc"|"backlight", bus|device }]
    property list<var> monitors: []
    property bool ready: false
    signal changed(string name, real value)

    function monitorFor(name: string) {
        return monitors.find(m => m.name === name) ?? null;
    }

    function valueFor(name: string): real {
        return monitorFor(name)?.value ?? -1;
    }

    function set(name: string, value: real): void {
        const idx = monitors.findIndex(m => m.name === name);
        if (idx < 0)
            return;
        value = Math.max(0, Math.min(1, value));
        const m = Object.assign({}, monitors[idx], { value });
        const copy = monitors.slice();
        copy[idx] = m;
        monitors = copy;
        changed(name, value);
        pending[name] = Math.round(value * 100);
        flush();
    }

    function increment(name: string, delta: real): void {
        const cur = valueFor(name);
        if (cur >= 0)
            set(name, cur + delta);
    }

    function focusedName(): string {
        const name = Hyprland.focusedMonitor?.name ?? "";
        if (monitorFor(name))
            return name;
        return monitors[0]?.name ?? "";
    }

    property var pending: ({})
    property var writing: ({})

    function flush(): void {
        for (const name in pending) {
            if (writing[name])
                continue;
            const m = monitorFor(name);
            if (!m)
                continue;
            const pct = pending[name];
            delete pending[name];
            writing[name] = true;
            const proc = writerComp.createObject(root, { name });
            proc.command = m.kind === "ddc"
                ? ["ddcutil", "setvcp", "10", String(pct), "--bus", String(m.bus), "--noverify", "--sleep-multiplier", ".1"]
                : ["brightnessctl", "-q", "-d", m.device, "set", pct + "%"];
            proc.running = true;
        }
    }

    Component {
        id: writerComp

        Process {
            property string name

            onExited: {
                delete root.writing[name];
                destroy();
                root.flush();
            }
        }
    }

    function report(msg: string): void {
        console.warn("Brightness:", msg);
        Quickshell.execDetached(["notify-send", "-a", "desktop-shell", "-u", "normal", "Brightness", msg]);
    }

    Process {
        id: backlight

        running: true
        command: ["sh", "-c", "brightnessctl -m -l 2>/dev/null | grep ',backlight,'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = [];
                for (const line of text.split("\n")) {
                    const f = line.split(",");
                    if (f.length < 5 || f[1] !== "backlight")
                        continue;
                    const max = parseInt(f[4]) || 1;
                    found.push({ name: "internal", kind: "backlight", device: f[0], value: parseInt(f[2]) / max });
                }
                root.monitors = [...root.monitors.filter(m => m.kind !== "backlight"), ...found];
                if (Config.brightness.external)
                    detect.running = true;
                else
                    root.ready = true;
            }
        }
    }

    Process {
        id: detect

        command: ["ddcutil", "detect", "--terse"]
        stdout: StdioCollector {
            onStreamFinished: {
                let bus = -1;
                const found = [];
                for (const line of text.split("\n")) {
                    let m = line.match(/I2C bus:\s+\/dev\/i2c-(\d+)/);
                    if (m) {
                        bus = parseInt(m[1]);
                        continue;
                    }
                    m = line.match(/DRM connector:\s+card\d+-(\S+)/);
                    if (m && bus >= 0) {
                        found.push({ name: m[1], kind: "ddc", bus, value: -1 });
                        bus = -1;
                    }
                }
                root.monitors = [...root.monitors.filter(m => m.kind !== "ddc"), ...found];
                root.ready = true;
                for (const m of found)
                    readerComp.createObject(root, { name: m.name, bus: m.bus }).running = true;
                if (found.length === 0 && root.monitors.length === 0)
                    console.info("Brightness: no controllable displays found");
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (/Permission denied|EACCES/i.test(text))
                    root.report("ddcutil cannot open /dev/i2c-* (permission denied); external brightness disabled");
            }
        }
        onExited: (code, status) => {
            if (code !== 0 && root.monitors.filter(m => m.kind === "ddc").length === 0)
                console.warn("Brightness: ddcutil detect exited with", code);
            root.ready = true;
        }
    }

    Component {
        id: readerComp

        Process {
            id: reader

            property string name
            property int bus

            command: ["ddcutil", "getvcp", "10", "--bus", String(bus), "--terse", "--sleep-multiplier", ".1"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const m = text.match(/VCP 10 C (\d+) (\d+)/);
                    if (m) {
                        const idx = root.monitors.findIndex(x => x.name === reader.name);
                        if (idx >= 0) {
                            const copy = root.monitors.slice();
                            copy[idx] = Object.assign({}, copy[idx], { value: parseInt(m[1]) / (parseInt(m[2]) || 100) });
                            root.monitors = copy;
                        }
                    }
                    reader.destroy();
                }
            }
        }
    }

    IpcHandler {
        target: "brightness"

        function increment(): void {
            root.increment(root.focusedName(), Config.brightness.step / 100);
        }

        function decrement(): void {
            root.increment(root.focusedName(), -Config.brightness.step / 100);
        }

        function set(value: real): void {
            root.set(root.focusedName(), value);
        }

        function get(): real {
            return root.valueFor(root.focusedName());
        }
    }
}
