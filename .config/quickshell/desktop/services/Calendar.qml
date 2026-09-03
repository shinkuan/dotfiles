pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

// Events from ICS collections (vdirsyncer layout) and events.json under
// `dir`, read through the desktop-calendar helper for the months around now.
Singleton {
    id: root

    property list<var> events: []
    property var eventMap: ({})   // "yyyy-MM-dd" -> events touching that day
    property bool loaded: false
    readonly property bool ready: loaded
    property string dirOverride: ""   // runtime only (IPC setDir), not persisted
    readonly property string dir: dirOverride || Config.calendar.dir || `${Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share"}/desktop-shell/calendar`
    // scratch entries next to the shell's other state are read as well
    readonly property string scratchDir: `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/desktop-shell/calendar`
    readonly property date today: clock.date
    property date rangeStart: new Date()
    property date rangeEnd: new Date()
    property bool queued: false

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    function dayKey(d: date): string {
        return Qt.formatDate(d, "yyyy-MM-dd");
    }

    // "yyyy-MM-dd" or "yyyy-MM-ddTHH:MM", always local time
    function parseLocal(s: string): date {
        const y = parseInt(s.substr(0, 4));
        const m = parseInt(s.substr(5, 2)) - 1;
        const d = parseInt(s.substr(8, 2));
        if (s.length > 10)
            return new Date(y, m, d, parseInt(s.substr(11, 2)), parseInt(s.substr(14, 2)));
        return new Date(y, m, d);
    }

    function refresh(): void {
        const t = new Date();
        rangeStart = new Date(t.getFullYear(), t.getMonth() - 1, 1);
        rangeEnd = new Date(t.getFullYear(), t.getMonth() + 3, 0);
        if (dump.running) {
            queued = true;
            return;
        }
        dump.command = ["desktop-calendar", "dump", "--from", dayKey(rangeStart), "--to", dayKey(rangeEnd), "--dir", dir, "--dir", scratchDir];
        dump.running = true;
    }

    function apply(list: var): void {
        const map = {};
        for (const ev of list) {
            ev.s = parseLocal(ev.start);
            ev.e = parseLocal(ev.end);
            // every day the event touches; an end at 00:00 belongs to the day before
            let d = new Date(ev.s.getFullYear(), ev.s.getMonth(), ev.s.getDate());
            const last = new Date(ev.e.getFullYear(), ev.e.getMonth(), ev.e.getDate());
            if (ev.allDay || (ev.e.getHours() === 0 && ev.e.getMinutes() === 0 && ev.e > ev.s))
                last.setDate(last.getDate() - 1);
            let guard = 0;
            while (d <= last && guard++ < 400) {
                const k = dayKey(d);
                (map[k] = map[k] ?? []).push(ev);
                d = new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1);
            }
        }
        for (const k in map)
            map[k].sort((a, b) => (a.allDay === b.allDay ? a.s - b.s : a.allDay ? -1 : 1));
        events = list;
        eventMap = map;
        loaded = true;
    }

    function eventsOn(d: date): list<var> {
        return eventMap[dayKey(d)] ?? [];
    }

    function hasEvents(d: date): bool {
        return (eventMap[dayKey(d)]?.length ?? 0) > 0;
    }

    // ongoing and future events starting within `days`, in start order
    function upcoming(days: int): list<var> {
        const now = new Date();
        const limit = new Date(now.getFullYear(), now.getMonth(), now.getDate() + days + 1);
        return events.filter(ev => ev.e > now && ev.s < limit).sort((a, b) => a.s - b.s);
    }

    Process {
        id: dump

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.apply(JSON.parse(text || "[]"));
                } catch (e) {
                    console.warn("Calendar: bad helper output:", e);
                }
                if (root.queued) {
                    root.queued = false;
                    root.refresh();
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "")
                    console.warn("Calendar:", text.trim());
            }
        }
    }

    Timer {
        interval: Math.max(1, Config.calendar.refreshMinutes) * 60000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    onDirChanged: refresh()
    Component.onCompleted: refresh()

    IpcHandler {
        target: "calendar"

        function refresh(): void {
            root.refresh();
        }

        function count(): int {
            return root.events.length;
        }

        function setDir(path: string): void {
            root.dirOverride = path;
        }

        function getDir(): string {
            return root.dir;
        }
    }
}
