pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property list<MprisPlayer> players: Mpris.players.values
    readonly property MprisPlayer active: players.find(p => p.isPlaying) ?? players.find(p => p.canControl) ?? null

    IpcHandler {
        target: "media"

        function playPause(): void {
            if (root.active?.canTogglePlaying)
                root.active.togglePlaying();
        }

        function next(): void {
            if (root.active?.canGoNext)
                root.active.next();
        }

        function previous(): void {
            if (root.active?.canGoPrevious)
                root.active.previous();
        }

        function stop(): void {
            root.active?.stop();
        }
    }
}
