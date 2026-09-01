pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../config"

// Idle inhibition lives on its own invisible surface so it never depends on
// any UI window being loaded. Three sources share the one inhibitor: the
// Keep-awake toggle, audio playback, and the joystick watcher.
Singleton {
    id: root

    readonly property bool keepAwake: ShellState.keepAwake
    property bool audioActive: false
    property bool joystickActive: false
    readonly property bool inhibited: keepAwake || audioActive || joystickActive

    function toggle(): void {
        ShellState.toggle("keepAwake");
    }

    // called by the joystick watcher; keeps the inhibitor for Config.idle.joystickHold seconds
    function activity(): void {
        joystickActive = true;
        joystickTimer.restart();
    }

    Timer {
        id: joystickTimer

        interval: Config.idle.joystickHold * 1000
        onTriggered: root.joystickActive = false
    }

    Timer {
        // debounce so short gaps between tracks don't drop the inhibitor
        id: audioTimer

        interval: 5000
        onTriggered: root.audioActive = false
    }

    Connections {
        target: Audio

        function onPlayingChanged(): void {
            if (!Config.idle.inhibitWhenAudio)
                return;
            if (Audio.playing) {
                audioTimer.stop();
                root.audioActive = true;
            } else {
                audioTimer.restart();
            }
        }
    }

    PanelWindow {
        id: window

        WlrLayershell.namespace: "desktop-idle"
        color: "transparent"
        mask: Region {}
        implicitWidth: 1
        implicitHeight: 1
        exclusionMode: ExclusionMode.Ignore

        IdleInhibitor {
            window: window
            enabled: root.inhibited
        }
    }

    IpcHandler {
        target: "idle"

        function toggle(): void {
            root.toggle();
        }

        function enable(): void {
            ShellState.set("keepAwake", true);
        }

        function disable(): void {
            ShellState.set("keepAwake", false);
        }

        function isEnabled(): bool {
            return root.keepAwake;
        }

        function isInhibited(): bool {
            return root.inhibited;
        }

        function activity(): void {
            root.activity();
        }
    }
}
