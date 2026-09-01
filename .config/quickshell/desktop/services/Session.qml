pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    function lock(): void {
        Quickshell.execDetached(["sh", "-c", "pidof hyprlock || hyprlock"]);
    }

    function suspend(): void {
        Quickshell.execDetached(["systemctl", "suspend"]);
    }

    function logout(): void {
        Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.exit()"]);
    }

    function reboot(): void {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }

    function shutdown(): void {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }

    IpcHandler {
        target: "session"

        function lock(): void {
            root.lock();
        }

        function suspend(): void {
            root.suspend();
        }

        function logout(): void {
            root.logout();
        }
    }
}
