import QtQuick
import Quickshell.Hyprland
import "../../config"
import "../../services"

// Hover panel anchored beside the bar. Geometry (x/y/width/height) is the
// interactive area handed to the surface mask; it includes the gap between
// bar and panel so the pointer can cross without leaving the surface.
Item {
    id: root

    required property HyprlandMonitor monitor
    property string current: ""
    property string loaded: ""
    property real anchorY: 0
    property bool shortcutActive: false
    property real barEdge: 0
    readonly property bool shown: current !== ""
    readonly property bool needsKeyboard: loader.item?.needsKeyboard ?? false
    readonly property int gap: 6
    readonly property int margin: 8

    x: barEdge
    y: Math.max(margin, Math.min(parent.height - panel.height - margin, anchorY - panel.height / 2))
    width: shown ? gap + panel.width : 0
    height: shown ? panel.height : 0

    Behavior on y {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutCubic
        }
    }

    function open(id: string, y: real): void {
        anchorY = y;
        if (registry[id] === undefined) {
            console.warn("Popouts: unknown popout", id);
            return;
        }
        loaded = id;
        current = id;
    }

    function openShortcut(id: string, y: real): void {
        if (current === id && shortcutActive) {
            close();
            return;
        }
        open(id, y);
        shortcutActive = true;
    }

    function close(): void {
        current = "";
        shortcutActive = false;
    }

    function contains(px: real, py: real): bool {
        return shown && px >= x && px < x + width && py >= y && py < y + height;
    }

    readonly property var registry: ({
        audio: audioComp,
        network: networkComp,
        vpn: vpnComp,
        bluetooth: bluetoothComp,
        calendar: calendarComp,
        resources: resourcesComp,
        power: powerComp,
        kgrid: kgridComp,
        notifications: notificationsComp
    })

    Component { id: audioComp; AudioPopout {} }
    Component { id: networkComp; NetworkPopout {} }
    Component { id: vpnComp; VpnPopout {} }
    Component { id: bluetoothComp; BluetoothPopout {} }
    Component { id: calendarComp; CalendarPopout {} }
    Component { id: resourcesComp; ResourcesPopout {} }
    Component { id: powerComp; PowerPopout {} }
    Component { id: kgridComp; KGridPopout { monitor: root.monitor } }
    Component { id: notificationsComp; NotificationsPopout {} }

    Rectangle {
        id: panel

        x: root.gap
        width: loader.item ? loader.item.width + Config.padding * 2 : 0
        height: loader.item ? loader.item.height + Config.padding * 2 : 0
        radius: Config.radiusLarge
        color: Colours.surfaceContainer
        border.width: 1
        border.color: Colours.alpha(Colours.outlineVariant, 0.5)
        clip: true

        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.92
        transformOrigin: Item.Left
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Config.animDurationFast
                onRunningChanged: {
                    if (!running && !root.shown)
                        root.loaded = "";
                }
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Config.animDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on width {
            NumberAnimation {
                duration: Config.animDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: Config.animDuration
                easing.type: Easing.OutCubic
            }
        }

        Loader {
            id: loader

            x: Config.padding
            y: Config.padding
            sourceComponent: root.loaded !== "" ? root.registry[root.loaded] : null
        }
    }
}
