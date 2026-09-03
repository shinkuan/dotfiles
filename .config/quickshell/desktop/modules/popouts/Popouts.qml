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

    // frame: the panel never travels along the bar. Another entry hovered
    // while it is out retracts it first (after a short dwell, so sliding
    // across entries does not flicker) and re-emerges at the new position.
    property string pendingId: ""
    property real pendingY: 0
    property bool snapping: false   // geometry writes that must not animate
    property bool swapping: false   // retracting only to re-emerge elsewhere
    readonly property bool retracting: frame && !shown && loaded !== "" && panel.x > -panel.width + 0.5

    // frame: a panel closer to the top/bottom band than the shader's blend
    // distance would bridge to it with a fillet, so it is either kept clear
    // of the band or pushed flush into it
    readonly property real bandT: frame ? Config.borderThickness : margin
    readonly property int bandGap: 28
    readonly property real rawY: Math.max(bandT, Math.min(parent.height - panel.height - bandT, anchorY - panel.height / 2))
    readonly property bool snapTop: frame && rawY - bandT < bandGap
    readonly property bool snapBottom: frame && !snapTop && parent.height - bandT - (rawY + panel.height) < bandGap
    // slot handed to the frame shader, in the surface's coordinates
    readonly property vector4d blobRect: frame && loaded !== "" ? Qt.vector4d(x + panel.x - 40, y - (snapTop ? 40 : 0), panel.width + 40, panel.height + (snapTop ? 40 : 0) + (snapBottom ? 40 : 0)) : Qt.vector4d(0, 0, 0, 0)

    x: horizontal ? Math.max(margin, Math.min(parent.width - panel.width - margin, anchorY - panel.width / 2)) : mirrored ? parent.width - barEdge - width : barEdge
    y: horizontal ? barEdge : snapTop ? bandT : snapBottom ? parent.height - bandT - panel.height : rawY
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

    // frame never animates y (see above); other styles glide between entries
    Behavior on y {
        enabled: !root.horizontal && !root.frame
        NumberAnimation {
            duration: Theme.spatialDuration
            easing.type: Theme.spatialType
            easing.bezierCurve: Theme.spatialCurve
        }
    }

    function open(id: string, y: real): void {
        if (registry[id] === undefined) {
            console.warn("Popouts: unknown popout", id);
            return;
        }
        closeGrace.stop();
        if (frame) {
            if (shown && id === current) {
                dwell.stop();
                pendingId = "";
                return;
            }
            if (shown || retracting) {
                pendingId = id;
                pendingY = y;
                if (shown)
                    dwell.restart();
                return;
            }
        }
        pendingId = "";
        swapping = false;
        snapping = !shown;
        anchorY = y;
        loaded = id;
        snapping = false;
        current = id;
    }

    Timer {
        id: dwell

        interval: 120
        onTriggered: {
            if (root.pendingId === "" || !root.shown)
                return;
            root.swapping = true;
            root.current = "";   // retract; the x animation reopens pendingId when done
        }
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
        closeGrace.stop();
        dwell.stop();
        pendingId = "";
        swapping = false;
        current = "";
        shortcutActive = false;
        keyboardOpened = false;
    }

    // the pointer left an entry but is still on the bar: keep the panel out
    // for a moment so the next entry morphs it instead of reopening it
    function closeSoon(): void {
        if (shown)
            closeGrace.restart();
    }

    function contains(px: real, py: real): bool {
        return shown && px >= x && px < x + width && py >= y && py < y + height;
    }

    Timer {
        id: closeGrace

        interval: 400
        onTriggered: root.close()
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
            enabled: root.frame && !root.snapping
            // the spring is for coming out; going back under the band is plain
            NumberAnimation {
                duration: root.shown ? Theme.spatialDuration : root.swapping ? Config.animDurationFast : Config.animDuration
                easing.type: root.shown ? Theme.spatialType : Easing.OutCubic
                easing.bezierCurve: Theme.spatialCurve
                onRunningChanged: {
                    if (running || root.shown || !root.frame)
                        return;
                    root.snapping = true;
                    root.loaded = "";
                    root.snapping = false;
                    // reopen outside this handler so the loader's binding is not re-entered
                    if (root.pendingId !== "")
                        Qt.callLater(root.open, root.pendingId, root.pendingY);
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
            enabled: !root.frame || root.shown
            NumberAnimation {
                duration: Theme.spatialDuration
                easing.type: Theme.spatialType
                easing.bezierCurve: Theme.spatialCurve
            }
        }

        Behavior on height {
            enabled: !root.frame || root.shown
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
