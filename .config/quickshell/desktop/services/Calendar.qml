pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

// Events and tasks. Local ICS collections / events.json under `dir` and, when
// `calendar.url` is set, a CalDAV server (Radicale) are read through the
// desktop-calendar helper for the months around now; task changes go back
// the same way. The helper keeps the last good server answer in a cache so a
// dead network still shows something (`cached` + `error` say so).
Singleton {
    id: root

    property list<var> events: []
    property list<var> todos: []
    property list<var> lists: []
    property var eventMap: ({})   // "yyyy-MM-dd" -> events touching that day
    property string error: ""     // last server problem; "" when the sync worked
    property bool cached: false
    property string synced: ""
    property bool loaded: false
    readonly property bool ready: loaded
    readonly property bool server: Config.calendar.url !== ""
    readonly property bool syncing: dump.running
    readonly property int openTodos: todos.filter(t => !t.done).length
    property string dirOverride: ""   // runtime only (IPC setDir), not persisted
    readonly property string dir: dirOverride || Config.calendar.dir || `${Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share"}/desktop-shell/calendar`
    readonly property string stateDir: `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/desktop-shell/calendar`
    readonly property date today: clock.date
    property date rangeStart: new Date()
    property date rangeEnd: new Date()
    property bool queued: false
    property list<var> edits: []   // pending helper commands, run one at a time

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

    function serverArgs(): list<string> {
        if (!server)
            return [];
        const c = Config.calendar;
        const args = ["--url", c.url, "--user", c.username, "--cache", `${stateDir}/cache.json`, "--done-days", String(c.doneDays)];
        if (c.passwordCommand !== "")
            args.push("--password-command", c.passwordCommand);
        if (c.collections.length > 0)
            args.push("--collections", c.collections.join(","));
        return args;
    }

    function refresh(): void {
        const t = new Date();
        rangeStart = new Date(t.getFullYear(), t.getMonth() - 1, 1);
        rangeEnd = new Date(t.getFullYear(), t.getMonth() + 3, 0);
        if (dump.running) {
            queued = true;
            return;
        }
        dump.command = ["desktop-calendar", "dump", "--from", dayKey(rangeStart), "--to", dayKey(rangeEnd), "--dir", dir, "--dir", stateDir, ...serverArgs()];
        dump.running = true;
    }

    function apply(data: var): void {
        const list = data.events ?? [];
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
        todos = (data.todos ?? []).map(t => {
            t.d = t.due !== "" ? parseLocal(t.due) : null;
            return t;
        });
        lists = data.lists ?? [];
        error = data.error ?? "";
        cached = data.cached ?? false;
        synced = data.synced ?? "";
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

    // days from today to a task's due date; NaN without one
    function dueOffset(t: var): real {
        if (!t.d)
            return NaN;
        const a = new Date(t.d.getFullYear(), t.d.getMonth(), t.d.getDate());
        const b = new Date(today.getFullYear(), today.getMonth(), today.getDate());
        return Math.round((a - b) / 86400000);
    }

    // flips a task at once and lets the server answer settle it on the next sync
    function toggleTodo(id: string): void {
        todos = todos.map(t => t.id === id ? Object.assign({}, t, { done: !t.done, pending: true }) : t);
        run(["todo", "toggle", id]);
    }

    function addTodo(text: string, due: string): void {
        if (text.trim() === "")
            return;
        const cmd = ["todo", "add", text.trim()];
        if (due !== "")
            cmd.push("--due", due);
        if (Config.calendar.todoList !== "")
            cmd.push("--list", Config.calendar.todoList);
        run(cmd);
    }

    function run(cmd: list<string>): void {
        edits = [...edits, cmd];
        if (!edit.running)
            next();
    }

    function next(): void {
        if (edits.length === 0) {
            refresh();
            return;
        }
        const cmd = edits[0];
        edits = edits.slice(1);
        edit.command = ["desktop-calendar", ...cmd, ...serverArgs()];
        edit.running = true;
    }

    Process {
        id: dump

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.apply(JSON.parse(text || "{}"));
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

    Process {
        id: edit

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const r = JSON.parse(text || "{}");
                    if (r.ok === false)
                        root.error = r.error ?? "task change failed";
                } catch (e) {
                    console.warn("Calendar: bad helper output:", e);
                }
                root.next();
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

    Connections {
        target: Config.calendar

        function onUrlChanged(): void {
            root.refresh();
        }
        function onUsernameChanged(): void {
            root.refresh();
        }
        function onCollectionsChanged(): void {
            root.refresh();
        }
    }

    IpcHandler {
        target: "calendar"

        function refresh(): void {
            root.refresh();
        }

        function sync(): void {
            root.refresh();
        }

        function count(): int {
            return root.events.length;
        }

        function status(): string {
            if (!root.server)
                return `local only: ${root.events.length} events`;
            return (root.error === "" ? "ok" : `error: ${root.error}${root.cached ? " (showing the cached copy)" : ""}`) + ` · ${root.events.length} events, ${root.todos.length} tasks, synced ${root.synced || "never"}`;
        }

        function setDir(path: string): void {
            root.dirOverride = path;
        }

        function getDir(): string {
            return root.dir;
        }
    }

    IpcHandler {
        target: "todo"

        function items(): string {
            return root.todos.map(t => `${t.done ? "[x]" : "[ ]"} ${t.id}  ${t.title}${t.due ? "  (" + t.due + ")" : ""}`).join("\n");
        }

        function count(): int {
            return root.openTodos;
        }

        function toggle(id: string): void {
            root.toggleTodo(id);
        }

        function add(text: string): void {
            root.addTodo(text, "");
        }
    }
}
