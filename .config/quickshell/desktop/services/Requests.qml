pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../config"

// Keyboard / IPC entry points. Per-screen surfaces listen and act only when
// they sit on the focused monitor.
Singleton {
    id: root

    signal popout(string id)
    signal closePopouts()
    signal session()

    GlobalShortcut {
        appid: "desktop"
        name: "launcher"
        description: "Toggle the launcher"
        onPressed: Launcher.toggle()
    }

    GlobalShortcut {
        appid: "desktop"
        name: "clipboard"
        description: "Open clipboard history"
        onPressed: {
            Launcher.show();
            Launcher.query = Config.launcher.clipPrefix;
        }
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

    GlobalShortcut {
        appid: "desktop"
        name: "overview"
        description: "Toggle the workspace overview"
        onPressed: Overview.toggle()
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
        target: "screenshot"

        function region(): void {
            Picker.start("save");
        }

        function regionCopy(): void {
            Picker.start("copy");
        }

        function cancel(): void {
            Picker.cancel();
        }

        // global logical coordinates; mode "save" or "copy"
        function capture(mode: string, x: int, y: int, w: int, h: int): void {
            Picker.mode = mode === "copy" ? "copy" : "save";
            Picker.confirm(x, y, w, h);
        }
    }

    GlobalShortcut {
        appid: "desktop"
        name: "screenshot"
        description: "Region screenshot (satty)"
        onPressed: Picker.start("save")
    }

    GlobalShortcut {
        appid: "desktop"
        name: "screenshotCopy"
        description: "Region screenshot to clipboard"
        onPressed: Picker.start("copy")
    }
}
