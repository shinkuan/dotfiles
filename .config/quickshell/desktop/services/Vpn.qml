pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// NetworkManager VPN / WireGuard connections via nmcli (Quickshell.Networking
// only models wifi and wired devices).
Singleton {
    id: root

    property list<var> connections: []
    readonly property list<var> active: connections.filter(c => c.active)
    readonly property bool available: nmcliFound
    property bool nmcliFound: true
    property bool busy: false

    function refresh(): void {
        if (!list.running)
            list.running = true;
    }

    function connect(conn): void {
        busy = true;
        Quickshell.execDetached(["nmcli", "connection", "up", "uuid", conn.uuid]);
        settle.restart();
    }

    function disconnect(conn): void {
        busy = true;
        Quickshell.execDetached(["nmcli", "connection", "down", "uuid", conn.uuid]);
        settle.restart();
    }

    function toggle(conn): void {
        if (conn.active)
            disconnect(conn);
        else
            connect(conn);
    }

    function disconnectAll(): void {
        for (const c of active)
            disconnect(c);
    }

    // nmcli -t escapes ':' inside values as '\:'
    function splitFields(line: string): list<string> {
        const out = [];
        let cur = "";
        for (let i = 0; i < line.length; i++) {
            const ch = line[i];
            if (ch === "\\" && i + 1 < line.length) {
                cur += line[++i];
            } else if (ch === ":") {
                out.push(cur);
                cur = "";
            } else {
                cur += ch;
            }
        }
        out.push(cur);
        return out;
    }

    Process {
        id: list

        command: ["nmcli", "-t", "-f", "NAME,UUID,TYPE,ACTIVE,DEVICE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    if (!line)
                        continue;
                    const f = root.splitFields(line);
                    if (f.length < 4 || (f[2] !== "vpn" && f[2] !== "wireguard"))
                        continue;
                    out.push({
                        name: f[0],
                        uuid: f[1],
                        type: f[2],
                        active: f[3] === "yes",
                        device: f[4] ?? ""
                    });
                }
                out.sort((a, b) => (b.active - a.active) || a.name.localeCompare(b.name));
                root.connections = out;
                root.busy = false;
            }
        }
        onExited: (code, status) => {
            if (code !== 0 && status !== 0) {
                root.nmcliFound = false;
                root.busy = false;
            }
        }
    }

    Process {
        id: monitor

        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: debounce.restart()
        }
    }

    Timer {
        id: debounce

        interval: 400
        onTriggered: root.refresh()
    }

    Timer {
        id: settle

        interval: 3000
        onTriggered: {
            root.busy = false;
            root.refresh();
        }
    }

    Component.onCompleted: refresh()
}
