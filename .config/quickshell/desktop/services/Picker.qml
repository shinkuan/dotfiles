pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

// Region screenshot state shared by the per-screen picker overlays. The
// overlay freezes the view and crops the final image out of that same frozen
// frame, so what was on screen while selecting is what gets saved.
Singleton {
    id: root

    property bool active: false
    property string mode: "save"   // "save" -> satty, "copy" -> clipboard
    property bool busy: false      // an overlay is writing its crop; further confirms are ignored
    property string pendingGeometry: ""

    function start(m: string): void {
        mode = m === "copy" ? "copy" : "save";
        busy = false;
        active = true;
    }

    function toggleMode(): void {
        mode = mode === "copy" ? "save" : "copy";
    }

    function cancel(): void {
        active = false;
        busy = false;
    }

    function scratchPath(): string {
        const dir = Quickshell.env("XDG_RUNTIME_DIR") || "/tmp";
        return `${dir}/desktop-shell-screenshot-${Date.now()}.png`;
    }

    // hand a finished PNG to satty or the clipboard; the file is removed afterwards
    function deliver(path: string): void {
        active = false;
        busy = false;
        Quickshell.execDetached(["sh", "-c", root.consumer(path)]);
    }

    // global logical coordinates, read from the live screen with grim once the
    // overlays have unmapped (ipc `capture`, and the fallback when a crop fails)
    function captureLive(x: int, y: int, w: int, h: int): void {
        if (w < 1 || h < 1)
            return;
        pendingGeometry = `${x},${y} ${w}x${h}`;
        active = false;
        busy = false;
        grab.restart();
    }

    function consumer(path: string): string {
        if (mode === "copy")
            return `wl-copy -t image/png < "${path}" && rm -f "${path}" && notify-send -a desktop-shell -i edit-copy "Screenshot" "Region copied to clipboard"`;
        const dir = `${Quickshell.env("HOME")}/${Config.screenshot.directory}`;
        return `mkdir -p "${dir}" && satty -f "${path}" -o "${dir}/%Y%m%d-%H%M%S.png" --copy-command wl-copy --early-exit; rm -f "${path}"`;
    }

    Timer {
        id: grab

        interval: 120
        onTriggered: {
            const path = root.scratchPath();
            Quickshell.execDetached(["sh", "-c", `grim -g "${root.pendingGeometry}" "${path}" && ${root.consumer(path)}`]);
        }
    }
}
