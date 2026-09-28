pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The Hyprland side lives in hypr/hyprland/gamemode.lua and keys off a flag
// file in the compositor's runtime dir, so the state follows the session,
// not the shell.
Singleton {
    id: root

    readonly property string flag: `${Quickshell.env("XDG_RUNTIME_DIR")}/hypr/${Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")}/gamemode`
    property bool enabled: false

    function set(on: bool): void {
        enabled = on;
        Quickshell.execDetached(["sh", "-c", `${on ? "touch" : "rm -f"} -- "$1" && hyprctl reload config-only`, "sh", flag]);
    }

    function toggle(): void {
        set(!enabled);
    }

    Process {
        running: true
        command: ["test", "-e", root.flag]
        onExited: code => root.enabled = code === 0
    }

    IpcHandler {
        target: "gameMode"

        function toggle(): void {
            root.toggle();
        }

        function enable(): void {
            root.set(true);
        }

        function disable(): void {
            root.set(false);
        }

        function isEnabled(): bool {
            return root.enabled;
        }
    }
}
