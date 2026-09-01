pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Grid model shared with kgrid.lua through the per-instance kgrid.json.
Singleton {
    id: root

    property int columns: 5
    property int rows: 5
    property list<var> activities: []   // [{ id, label }]
    readonly property var current: parse(Hyprland.focusedWorkspace?.name ?? "")

    function parse(name: string): var {
        const m = name.match(/^(.+):\((\d+) (\d+)\)$/);
        if (!m)
            return null;
        return { activity: m[1], x: parseInt(m[2]), y: parseInt(m[3]) };
    }

    function labelFor(id: string): string {
        return activities.find(a => a.id === id)?.label ?? id;
    }

    function cellName(activity: string, x: int, y: int): string {
        return `${activity}:(${x} ${y})`;
    }

    // occupied cells of one activity, as "x,y" -> window count
    function occupancy(activity: string): var {
        const out = {};
        for (const ws of Hyprland.workspaces.values) {
            const p = parse(ws.name);
            if (p && p.activity === activity && (ws.lastIpcObject?.windows ?? 0) > 0)
                out[p.x + "," + p.y] = ws.lastIpcObject.windows;
        }
        return out;
    }

    function switchTo(activity: string, x: int, y: int): void {
        Hyprland.dispatch(`(function() KGrid.switch_name("${cellName(activity, x, y)}") return hl.dsp.no_op() end)()`);
    }

    function switchActivity(activity: string): void {
        Hyprland.dispatch(`(function() KGrid.switch_activity("${activity}") return hl.dsp.no_op() end)()`);
    }

    function moveWindow(address: string, activity: string, x: int, y: int): void {
        Hyprland.dispatch(`(function() KGrid.move_window_to_name("${cellName(activity, x, y)}", "${address}") return hl.dsp.no_op() end)()`);
    }

    FileView {
        path: `${Quickshell.env("XDG_RUNTIME_DIR")}/hypr/${Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")}/kgrid.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const doc = JSON.parse(text());
                root.columns = doc.W ?? 5;
                root.rows = doc.H ?? 5;
                root.activities = doc.activities ?? [];
            } catch (e) {
                console.warn("KGrid: cannot parse kgrid.json:", e);
            }
        }
        onLoadFailed: err => {
            if (err !== FileViewError.FileNotFound)
                console.warn("KGrid: cannot read kgrid.json:", FileViewError.toString(err));
        }
    }
}
