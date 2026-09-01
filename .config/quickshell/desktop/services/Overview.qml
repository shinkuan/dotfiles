pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// KGrid overview state: which activity is shown and the keyboard-selected cell.
Singleton {
    id: root

    property bool open: false
    property string activity: ""
    property int selX: 1
    property int selY: 1

    function show(): void {
        const c = KGrid.current;
        activity = c?.activity ?? (KGrid.activities[0]?.id ?? "main");
        selX = c?.x ?? 1;
        selY = c?.y ?? 1;
        refresh();
        open = true;
    }

    function hide(): void {
        open = false;
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
    }

    function nextActivity(delta: int): void {
        const ids = KGrid.activities.map(a => a.id);
        if (ids.length === 0)
            return;
        const i = Math.max(0, ids.indexOf(activity));
        activity = ids[(i + delta + ids.length) % ids.length];
    }

    function go(): void {
        KGrid.switchTo(activity, selX, selY);
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
