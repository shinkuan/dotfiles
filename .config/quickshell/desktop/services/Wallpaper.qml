pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string dir: `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/wallpaper`
    property string path: ""

    IpcHandler {
        target: "wallpaper"

        function set(path: string): void {
            root.path = path;
        }

        function get(): string {
            return root.path;
        }
    }

    // see Colours: the directory must exist before the watcher is armed
    Process {
        command: ["mkdir", "-p", root.dir]
        running: true
        onExited: file.path = root.dir + "/path.txt"
    }

    FileView {
        id: file

        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.path = text().trim()
    }
}
