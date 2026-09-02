import QtQuick
import Quickshell.Hyprland
import "../../config"
import "../../services"
import "../../components"

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
    property bool keyboardOpened: false
    property real barEdge: 0
    readonly property bool shown: current !== ""
    readonly property bool needsKeyboard: loader.item?.needsKeyboard ?? false
    readonly property int gap: Theme.frame ? 0 : 6
    readonly property int margin: 8

    readonly property bool horizontal: Theme.barTop
    readonly property bool mirrored: Theme.barRight
    readonly property bool frame: Theme.frame
    // slot handed to the frame shader, in the surface's coordinates
    readonly property vector4d blobRect: frame && loaded !== "" ? Qt.vector4d(x + panel.x - 40, y, panel.width + 40, panel.height) : Qt.vector4d(0, 0, 0, 0)

    x: horizontal ? Math.max(margin, Math.min(parent.width - panel.width - margin, anchorY - panel.width / 2)) : mirrored ? parent.width - barEdge - width : barEdge
    y: horizontal ? barEdge : Math.max(margin, Math.min(parent.height - panel.height - margin, anchorY - panel.height / 2))
    width: frame ? Math.max(0, panel.width + panel.x) : shown ? (horizontal ? panel.width : gap + panel.width) : 0
    height: frame ? panel.height : shown ? (horizontal ? gap + panel.height : panel.height) : 0
    clip: frame

    Behavior on x {
        enabled: root.horizontal
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on y {
        enabled: !root.horizontal
        NumberAnimation {
            duration: Theme.spatialDuration
            easing.type: Theme.spatialType
            easing.bezierCurve: Theme.spatialCurve
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

    function openShortcut(id: string, y: real, keyboard: bool): void {
        if (current === id && shortcutActive) {
            close();
            return;
        }
        open(id, y);
        shortcutActive = true;
        keyboardOpened = keyboard;
    }

    function close(): void {
        current = "";
        shortcutActive = false;
        keyboardOpened = false;
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
        notifications: notificationsComp,
        media: mediaComp,
        window: windowComp
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
    Component { id: mediaComp; MediaPopout {} }
    Component { id: windowComp; WindowPopout {} }

    Surface {
        id: panel

        // frame: slides out from under the bar band
        x: root.frame ? (root.shown ? 0 : -width) : root.horizontal || root.mirrored ? 0 : root.gap
        y: root.horizontal ? root.gap : 0
        width: loader.item ? loader.item.width + Config.padding * 2 : 0
        height: loader.item ? loader.item.height + Config.padding * 2 : 0

        color: root.frame ? "transparent" : Theme.panel
        shadow: !root.frame
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : Theme.popScale
        transformOrigin: root.horizontal ? Item.Top : root.mirrored ? Item.Right : Item.Left
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Config.animDurationFast
                onRunningChanged: {
                    if (!running && !root.shown && !root.frame)
                        root.loaded = "";
                }
            }
        }

        Behavior on x {
            enabled: root.frame
            NumberAnimation {
                duration: Theme.spatialDuration
                easing.type: Theme.spatialType
                easing.bezierCurve: Theme.spatialCurve
                onRunningChanged: {
                    if (!running && !root.shown && root.frame)
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
                duration: Theme.spatialDuration
                easing.type: Theme.spatialType
                easing.bezierCurve: Theme.spatialCurve
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: Theme.spatialDuration
                easing.type: Theme.spatialType
                easing.bezierCurve: Theme.spatialCurve
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
