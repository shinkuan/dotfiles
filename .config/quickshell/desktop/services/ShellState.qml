pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// User toggles that must survive shell restarts (not just reloads).
Singleton {
    id: root

    readonly property string dir: `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/desktop-shell`
    readonly property bool barPinned: adapter.barPinned ?? false
    readonly property bool dnd: adapter.dnd ?? false
    readonly property bool keepAwake: adapter.keepAwake ?? false
    readonly property bool desktopClock: adapter.desktopClock ?? true
    property bool ready: false
    property var queued: ({})
    property Item activeEntry: null   // bar entry that last opened a popout (not persisted)

    function set(key: string, value): void {
        adapter[key] = value;
        if (ready) {
            file.writeAdapter();
        } else {
            // the file load would overwrite it; re-apply once loaded
            const q = Object.assign({}, queued);
            q[key] = value;
            queued = q;
        }
    }

    function flushQueued(): void {
        ready = true;
        const keys = Object.keys(queued);
        for (const k of keys)
            adapter[k] = queued[k];
        queued = {};
        if (keys.length > 0)
            file.writeAdapter();
    }

    function toggle(key: string): void {
        set(key, !adapter[key]);
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", dir])

    FileView {
        id: file

        path: root.dir + "/state.json"
        printErrors: false
        onLoaded: root.flushQueued()
        onLoadFailed: root.flushQueued()

        adapter: JsonAdapter {
            id: adapter

            property bool barPinned: false
            property bool dnd: false
            property bool keepAwake: false
            property bool desktopClock: true
        }
    }

    IpcHandler {
        target: "bar"

        function toggle(): void {
            root.toggle("barPinned");
        }

        function pin(): void {
            root.set("barPinned", true);
        }

        function unpin(): void {
            root.set("barPinned", false);
        }

        function isPinned(): bool {
            return adapter.barPinned;
        }
    }

    IpcHandler {
        target: "desktopClock"

        function toggle(): void {
            root.toggle("desktopClock");
        }

        function enable(): void {
            root.set("desktopClock", true);
        }

        function disable(): void {
            root.set("desktopClock", false);
        }

        function isEnabled(): bool {
            return adapter.desktopClock;
        }
    }
}
