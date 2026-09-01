pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

Singleton {
    id: root

    property real cpu: 0
    property real cpuTemp: 0
    property real memUsed: 0
    property real memTotal: 0
    property real swapUsed: 0
    property real swapTotal: 0
    property var gpu: null    // { util, memUsed, memTotal, temp }
    property list<var> disks: []   // { mount, used, size }
    property real netRx: 0    // bytes / s
    property real netTx: 0
    property int watchers: 0      // >0 while a consumer is visible -> faster polling

    readonly property real memRatio: memTotal > 0 ? memUsed / memTotal : 0

    function fmtBytes(b: real, decimals: int): string {
        const units = ["B", "K", "M", "G", "T"];
        let i = 0;
        while (b >= 1024 && i < units.length - 1) {
            b /= 1024;
            i++;
        }
        return b.toFixed(i === 0 ? 0 : (decimals ?? 1)) + units[i];
    }

    property var lastCpu: null
    property var lastNet: null
    property real lastNetTime: 0

    FileView {
        id: stat

        path: "/proc/stat"
        onLoaded: {
            const line = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = line[3] + line[4];
            const total = line.reduce((a, b) => a + b, 0);
            if (root.lastCpu) {
                const dt = total - root.lastCpu.total;
                root.cpu = dt > 0 ? 1 - (idle - root.lastCpu.idle) / dt : 0;
            }
            root.lastCpu = { idle, total };
        }
    }

    FileView {
        id: meminfo

        path: "/proc/meminfo"
        onLoaded: {
            const kv = {};
            for (const line of text().split("\n")) {
                const m = line.match(/^(\w+):\s+(\d+)/);
                if (m)
                    kv[m[1]] = parseInt(m[2]) * 1024;
            }
            root.memTotal = kv.MemTotal ?? 0;
            root.memUsed = (kv.MemTotal ?? 0) - (kv.MemAvailable ?? 0);
            root.swapTotal = kv.SwapTotal ?? 0;
            root.swapUsed = (kv.SwapTotal ?? 0) - (kv.SwapFree ?? 0);
        }
    }

    FileView {
        id: netdev

        path: "/proc/net/dev"
        onLoaded: {
            let rx = 0, tx = 0;
            for (const line of text().split("\n").slice(2)) {
                const m = line.trim().match(/^([^:]+):\s*(.*)$/);
                if (!m || m[1] === "lo")
                    continue;
                const f = m[2].trim().split(/\s+/).map(Number);
                rx += f[0];
                tx += f[8];
            }
            const now = Date.now();
            if (root.lastNet && now > root.lastNetTime) {
                const dt = (now - root.lastNetTime) / 1000;
                root.netRx = (rx - root.lastNet.rx) / dt;
                root.netTx = (tx - root.lastNet.tx) / dt;
            }
            root.lastNet = { rx, tx };
            root.lastNetTime = now;
        }
    }

    Timer {
        interval: root.watchers > 0 ? 1000 : Config.resources.interval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            netdev.reload();
            if (!temp.running)
                temp.running = true;
            if (root.watchers > 0 && !gpuProc.running && root.gpu !== undefined)
                gpuProc.running = true;
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!df.running)
                df.running = true;
            if (root.watchers === 0 && !gpuProc.running && root.gpu !== undefined)
                gpuProc.running = true;
        }
    }

    Process {
        id: temp

        command: ["sh", "-c", "cat /sys/class/hwmon/hwmon*/temp1_input 2>/dev/null | sort -n | tail -1"]
        stdout: StdioCollector {
            onStreamFinished: root.cpuTemp = (parseInt(text) || 0) / 1000
        }
    }

    Process {
        id: gpuProc

        command: ["nvidia-smi", "--query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu", "--format=csv,noheader,nounits"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",").map(s => parseFloat(s));
                if (f.length >= 4 && !isNaN(f[0]))
                    root.gpu = { util: f[0] / 100, memUsed: f[1] * 1048576, memTotal: f[2] * 1048576, temp: f[3] };
            }
        }
        onExited: (code, status) => {
            // no nvidia-smi (or no GPU): stop trying
            if (code !== 0)
                root.gpu = undefined;
        }
    }

    Process {
        id: df

        command: ["df", "-B1", "--output=target,used,size", "-x", "tmpfs", "-x", "devtmpfs", "-x", "efivarfs", "-x", "overlay", "-x", "squashfs"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n").slice(1)) {
                    const f = line.trim().split(/\s+/);
                    if (f.length < 3 || f[0].startsWith("/boot") || f[0].startsWith("/run"))
                        continue;
                    out.push({ mount: f[0], used: parseFloat(f[1]), size: parseFloat(f[2]) });
                }
                root.disks = out;
            }
        }
    }
}
