pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// A deck summoned at the pointer (or the screen centre) by IPC / keybind.
Singleton {
    id: root

    property bool open: false
    property bool centered: false
    property real x: 0   // global logical coords of the pointer at summon time
    property real y: 0

    function show(center: bool): void {
        centered = center;
        if (center)
            open = true;
        else
            cursor.running = true;
    }

    function hide(): void {
        open = false;
    }

    function toggle(center: bool): void {
        if (open)
            hide();
        else
            show(center);
    }

    Process {
        id: cursor

        command: ["hyprctl", "cursorpos", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const p = JSON.parse(text);
                    root.x = p.x;
                    root.y = p.y;
                } catch (e) {
                    root.centered = true;
                }
                root.open = true;
            }
        }
    }

    IpcHandler {
        target: "summon"

        function toggle(): void {
            root.toggle(false);
        }

        function open(): void {
            root.show(false);
        }

        function center(): void {
            root.toggle(true);
        }

        function hide(): void {
            root.hide();
        }
    }
}
