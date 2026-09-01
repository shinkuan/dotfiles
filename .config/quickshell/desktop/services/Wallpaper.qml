pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

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

    FileView {
        path: `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/wallpaper/path.txt`
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.path = text().trim()
    }
}
