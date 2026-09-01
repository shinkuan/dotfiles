pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var palette: ({})
    readonly property string mode: meta.mode ?? "dark"
    property var meta: ({})

    // common roles with fallbacks so the shell renders before first generation
    readonly property color surface: c("surface", "#151312")
    readonly property color surfaceContainer: c("surfaceContainer", "#221f1e")
    readonly property color surfaceContainerHigh: c("surfaceContainerHigh", "#2c2929")
    readonly property color onSurface: c("onSurface", "#e8e1e0")
    readonly property color onSurfaceVariant: c("onSurfaceVariant", "#d3c3c0")
    readonly property color outline: c("outline", "#9c8e8b")
    readonly property color primary: c("primary", "#e1bfb9")
    readonly property color onPrimary: c("onPrimary", "#412b27")
    readonly property color secondary: c("secondary", "#d5c3bf")
    readonly property color error: c("error", "#ffb4ab")

    function c(name: string, fallback: string): color {
        const v = root.palette[name];
        return v ? "#" + v : fallback;
    }

    function alpha(base: color, a: real): color {
        return Qt.rgba(base.r, base.g, base.b, a);
    }

    FileView {
        id: file

        path: `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/scheme/colours.json`
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const doc = JSON.parse(text());
                root.palette = doc.colours ?? {};
                root.meta = doc;
            } catch (e) {
                console.warn("Colours: failed to parse colours.json:", e);
            }
        }
    }
}
