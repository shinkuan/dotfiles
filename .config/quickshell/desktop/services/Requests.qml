pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Keyboard / IPC entry points. Per-screen surfaces listen and act only when
// they sit on the focused monitor.
Singleton {
    id: root

    signal popout(string id)
    signal closePopouts()
    signal launcher(bool toggleOnly)
    signal session()
    signal notifications()
    signal screenshot(string mode)

    GlobalShortcut {
        appid: "desktop"
        name: "launcher"
        description: "Toggle the launcher"
        onPressed: root.launcher(false)
    }

    GlobalShortcut {
        appid: "desktop"
        name: "session"
        description: "Open the session / power menu"
        onPressed: root.session()
    }

    GlobalShortcut {
        appid: "desktop"
        name: "audio"
        description: "Open the audio popout"
        onPressed: root.popout("audio")
    }

    GlobalShortcut {
        appid: "desktop"
        name: "network"
        description: "Open the network popout"
        onPressed: root.popout("network")
    }

    GlobalShortcut {
        appid: "desktop"
        name: "bluetooth"
        description: "Open the bluetooth popout"
        onPressed: root.popout("bluetooth")
    }

    GlobalShortcut {
        appid: "desktop"
        name: "notifications"
        description: "Open the notification centre"
        onPressed: root.popout("notifications")
    }

    GlobalShortcut {
        appid: "desktop"
        name: "kgrid"
        description: "Open the KGrid popout"
        onPressed: root.popout("kgrid")
    }

    IpcHandler {
        target: "popout"

        function open(id: string): void {
            root.popout(id);
        }

        function close(): void {
            root.closePopouts();
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.launcher(false);
        }
    }

    IpcHandler {
        target: "screenshot"

        function region(): void {
            root.screenshot("region");
        }

        function regionCopy(): void {
            root.screenshot("copy");
        }
    }
}
