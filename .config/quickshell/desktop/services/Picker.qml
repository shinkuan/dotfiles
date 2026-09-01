pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

// Region screenshot state shared by the per-screen picker overlays. The
// overlay only freezes the view; grim takes the final image after the
// overlay has unmapped.
Singleton {
    id: root

    property bool active: false
    property string mode: "save"   // "save" -> satty, "copy" -> clipboard
    property string pendingGeometry: ""

    function start(m: string): void {
        mode = m === "copy" ? "copy" : "save";
        active = true;
    }

    function toggleMode(): void {
        mode = mode === "copy" ? "save" : "copy";
    }

    function cancel(): void {
        active = false;
    }

    // global logical coordinates, as understood by grim -g
    function confirm(x: int, y: int, w: int, h: int): void {
        if (w < 1 || h < 1)
            return;
        pendingGeometry = `${x},${y} ${w}x${h}`;
        active = false;
        grab.restart();
    }

    Timer {
        id: grab

        interval: 120
        onTriggered: {
            const dir = `${Quickshell.env("HOME")}/${Config.screenshot.directory}`;
            const geometry = root.pendingGeometry;
            if (root.mode === "copy")
                Quickshell.execDetached(["sh", "-c", `grim -g "${geometry}" - | wl-copy && notify-send -a desktop-shell -i edit-copy "Screenshot" "Region copied to clipboard"`]);
            else
                Quickshell.execDetached(["sh", "-c", `mkdir -p "${dir}" && grim -g "${geometry}" - | satty -f - -o "${dir}/%Y%m%d-%H%M%S.png" --copy-command wl-copy --early-exit`]);
        }
    }
}
