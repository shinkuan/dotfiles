pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var palette: ({})
    property var meta: ({})
    readonly property bool light: (meta.mode ?? "dark") === "light"

    // fallbacks let the shell render before the first scheme generation
    readonly property color background: c("background", "#151312")
    readonly property color surface: c("surface", "#151312")
    readonly property color surfaceDim: c("surfaceDim", "#151312")
    readonly property color surfaceBright: c("surfaceBright", "#3c3838")
    readonly property color surfaceContainerLowest: c("surfaceContainerLowest", "#100e0d")
    readonly property color surfaceContainerLow: c("surfaceContainerLow", "#1e1b1a")
    readonly property color surfaceContainer: c("surfaceContainer", "#221f1e")
    readonly property color surfaceContainerHigh: c("surfaceContainerHigh", "#2c2929")
    readonly property color surfaceContainerHighest: c("surfaceContainerHighest", "#373433")
    readonly property color surfaceVariant: c("surfaceVariant", "#4f4442")
    readonly property color onSurface: c("onSurface", "#e8e1e0")
    readonly property color onSurfaceVariant: c("onSurfaceVariant", "#d3c3c0")
    readonly property color outline: c("outline", "#9c8e8b")
    readonly property color outlineVariant: c("outlineVariant", "#4f4442")
    readonly property color inverseSurface: c("inverseSurface", "#e8e1e0")
    readonly property color inverseOnSurface: c("inverseOnSurface", "#33302f")
    readonly property color primary: c("primary", "#e1bfb9")
    readonly property color onPrimary: c("onPrimary", "#412b27")
    readonly property color primaryContainer: c("primaryContainer", "#7b605b")
    readonly property color onPrimaryContainer: c("onPrimaryContainer", "#ffded8")
    readonly property color secondary: c("secondary", "#d5c3bf")
    readonly property color onSecondary: c("onSecondary", "#392e2c")
    readonly property color secondaryContainer: c("secondaryContainer", "#534644")
    readonly property color onSecondaryContainer: c("onSecondaryContainer", "#c6b5b1")
    readonly property color tertiary: c("tertiary", "#d4c5a8")
    readonly property color onTertiary: c("onTertiary", "#392f1b")
    readonly property color tertiaryContainer: c("tertiaryContainer", "#71654d")
    readonly property color onTertiaryContainer: c("onTertiaryContainer", "#f4e3c5")
    readonly property color error: c("error", "#ffb4ab")
    readonly property color onError: c("onError", "#690005")
    readonly property color errorContainer: c("errorContainer", "#93000a")
    readonly property color onErrorContainer: c("onErrorContainer", "#ffdad6")
    readonly property color success: c("success", "#b5ccba")
    readonly property color onSuccess: c("onSuccess", "#213528")
    readonly property color scrim: c("scrim", "#000000")

    function c(name: string, fallback: string): color {
        const v = root.palette[name];
        return v ? "#" + v : fallback;
    }

    function alpha(base: color, a: real): color {
        return Qt.rgba(base.r, base.g, base.b, a);
    }

    function mix(a: color, b: color, t: real): color {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
    }

    FileView {
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
