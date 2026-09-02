pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Appearance constants plus the hot-loaded config.json (any key may be
// omitted; the defaults declared on the adapter apply).
Singleton {
    id: root

    readonly property string fontFamily: Theme.font
    readonly property string fontFamilyMono: Theme.fontMono
    readonly property string iconFont: "Material Symbols Rounded"
    readonly property int fontSize: 13
    readonly property int iconSize: 21

    readonly property int radius: Theme.radiusItem
    readonly property int radiusLarge: Theme.radius
    readonly property int padding: Theme.padding

    readonly property real animSpeed: adapter.animation.scale
    readonly property int animDurationFast: Math.round(150 * animSpeed)
    readonly property int animDuration: Math.round(300 * animSpeed)
    readonly property int animDurationSlow: Math.round(500 * animSpeed)

    readonly property int borderThickness: adapter.border.thickness
    readonly property int borderRounding: adapter.border.rounding
    readonly property int barWidth: Theme.barSpan
    readonly property int barPinThreshold: adapter.bar.pinThreshold

    readonly property alias bar: adapter.bar
    readonly property alias appearance: adapter.appearance
    readonly property alias popouts: adapter.popouts
    readonly property alias osd: adapter.osd
    readonly property alias kgrid: adapter.kgrid
    readonly property alias desktopClock: adapter.desktopClock
    readonly property alias notifications: adapter.notifications
    readonly property alias idle: adapter.idle
    readonly property alias launcher: adapter.launcher
    readonly property alias screenshot: adapter.screenshot
    readonly property alias resources: adapter.resources
    readonly property alias brightness: adapter.brightness
    readonly property list<string> styles: ["rim", "ledger", "capsule", "signal", "poster", "classic"]

    // writes config.json back through the adapter (keys are preserved)
    function setStyle(name: string): void {
        if (!styles.includes(name)) {
            console.warn("Config: unknown style", name);
            return;
        }
        adapter.appearance.style = name;
        file.writeAdapter();
    }

    IpcHandler {
        target: "theme"

        function set(name: string): void {
            root.setStyle(name);
        }

        function get(): string {
            return adapter.appearance.style;
        }

        function cycle(): void {
            const i = root.styles.indexOf(adapter.appearance.style);
            root.setStyle(root.styles[(i + 1) % root.styles.length]);
        }
    }

    FileView {
        id: file

        path: Quickshell.shellDir + "/config.json"
        watchChanges: true
        onFileChanged: reload()
        onLoadFailed: err => {
            if (err !== FileViewError.FileNotFound)
                console.warn("Config: cannot load config.json:", FileViewError.toString(err));
        }

        adapter: JsonAdapter {
            id: adapter

            property JsonObject appearance: JsonObject {
                property string style: "rim"   // rim | ledger | capsule | signal | poster | classic
            }
            property JsonObject animation: JsonObject {
                property real scale: 0.8
            }
            property JsonObject border: JsonObject {
                property int thickness: 10
                property int rounding: 25
            }
            property JsonObject bar: JsonObject {
                property int width: 44
                property int pinThreshold: 20
                property bool showResources: true
            }
            property JsonObject popouts: JsonObject {
                property bool showOnHover: true
                property int width: 340
                property int listHeight: 320
            }
            property JsonObject osd: JsonObject {
                property int hideDelay: 2000
            }
            property JsonObject kgrid: JsonObject {
                property bool osd: true
                property int hideDelay: 1000
            }
            property JsonObject desktopClock: JsonObject {
                property string position: "bottom-right"
                property int margin: 48
            }
            property JsonObject notifications: JsonObject {
                property int timeout: 5000
                property int criticalTimeout: 0
                property int maxHistory: 200
                property int width: 380
            }
            property JsonObject idle: JsonObject {
                property bool inhibitWhenAudio: true
                property int joystickHold: 60
            }
            property JsonObject launcher: JsonObject {
                property int maxResults: 9
                property string actionPrefix: ">"
                property string calcPrefix: "="
                property string clipPrefix: ";"
                property string emojiPrefix: ":"
                property string emojiFile: "/usr/share/unicode/emoji/emoji-test.txt"
                property bool fuzzy: true
                property bool showDangerous: false
                property var actions: []
            }
            property JsonObject screenshot: JsonObject {
                property string directory: "Pictures/Screenshots"
            }
            property JsonObject resources: JsonObject {
                property int interval: 2000
            }
            property JsonObject brightness: JsonObject {
                property bool external: true
                property int step: 5
            }
        }
    }
}
