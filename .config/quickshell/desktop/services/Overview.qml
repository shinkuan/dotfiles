pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// KGrid overview state. The selection *is* the current workspace: it starts on
// the cell the overview was opened from and every move switches there for real,
// so Enter only has to close. Esc goes back to the cell it started on.
Singleton {
    id: root

    property bool open: false
    property string activity: ""
    property int selX: 1
    property int selY: 1
    property var origin: null   // cell the overview was opened on, for Esc

    function show(): void {
        const c = KGrid.current;
        activity = c?.activity ?? (KGrid.activities[0]?.id ?? "main");
        selX = c?.x ?? 1;
        selY = c?.y ?? 1;
        origin = c ? { activity: c.activity, x: c.x, y: c.y } : null;
        refresh();
        open = true;
    }

    function hide(): void {
        open = false;
        origin = null;
    }

    function toggle(): void {
        if (open)
            hide();
        else
            show();
    }

    function refresh(): void {
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();
    }

    function moveSelection(dx: int, dy: int): void {
        selX = Math.max(1, Math.min(KGrid.columns, selX + dx));
        selY = Math.max(1, Math.min(KGrid.rows, selY + dy));
        follow();
    }

    // shown activity, and the workspace along with it; a drag preview assigns
    // `activity` directly instead, so the desktop stays put mid-drag
    function setActivity(id: string): void {
        if (!id)
            return;
        activity = id;
        const c = KGrid.current;
        if (!c || c.activity !== id)
            KGrid.switchActivity(id);
    }

    function nextActivity(delta: int): void {
        const ids = KGrid.activities.map(a => a.id);
        if (ids.length === 0)
            return;
        const i = Math.max(0, ids.indexOf(activity));
        setActivity(ids[(i + delta + ids.length) % ids.length]);
    }

    // put the real workspace on the selected cell, unless it is already there
    function follow(): void {
        const c = KGrid.current;
        if (!c || c.activity !== activity || c.x !== selX || c.y !== selY)
            KGrid.switchTo(activity, selX, selY);
    }

    function go(): void {
        follow();
        hide();
    }

    function cancel(): void {
        const o = origin;
        const c = KGrid.current;
        if (o && (!c || c.activity !== o.activity || c.x !== o.x || c.y !== o.y))
            KGrid.switchTo(o.activity, o.x, o.y);
        hide();
    }

    IpcHandler {
        target: "overview"

        function toggle(): void {
            root.toggle();
        }

        function open(): void {
            root.show();
        }

        function close(): void {
            root.hide();
        }
    }
}
