pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property alias pinned: persist.pinned

    function setPinned(value: bool): void {
        persist.pinned = value;
    }

    PersistentProperties {
        id: persist

        reloadableId: "desktopBarState"

        property bool pinned: false
    }

    IpcHandler {
        target: "bar"

        function toggle(): void {
            persist.pinned = !persist.pinned;
        }

        // "show" collides with the `qs ipc show` subcommand, hence pin/unpin
        function pin(): void {
            persist.pinned = true;
        }

        function unpin(): void {
            persist.pinned = false;
        }

        function isPinned(): bool {
            return persist.pinned;
        }
    }
}
