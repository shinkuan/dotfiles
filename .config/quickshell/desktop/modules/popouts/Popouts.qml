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

    // frame: an entry hovered while the panel is out morphs it there with
    // the spring (caelestia style); one hovered while it slides back under
    // the band is queued so it never re-emerges at the old position
    property string pendingId: ""
    property real pendingY: 0
    property bool snapping: false   // geometry writes that must not animate
    readonly property bool retracting: frame && !shown && loaded !== "" && panel.x > -panel.width + 0.5

    // frame: a panel closer to the top/bottom band than the shader's blend
    // distance would bridge to it with a fillet, so it is either kept clear
    // of the band or pushed flush into it
    readonly property real bandT: frame ? Config.borderThickness : margin
    readonly property int bandGap: 28
    // placement uses the content's final size, not the animating panel size,
    // so the move and the resize run as one spring instead of one after the other
    readonly property real targetH: loader.item ? loader.item.height + Config.padding * 2 : 0
    readonly property real rawY: Math.max(bandT, Math.min(parent.height - targetH - bandT, anchorY - targetH / 2))
    readonly property bool snapTop: frame && rawY - bandT < bandGap
    readonly property bool snapBottom: frame && !snapTop && parent.height - bandT - (rawY + targetH) < bandGap
    // slot handed to the frame shader, in the surface's coordinates
    readonly property vector4d blobRect: frame && loaded !== "" ? Qt.vector4d(x + panel.x - 40, y - (snapTop ? 40 : 0), panel.width + 40, panel.height + (snapTop ? 40 : 0) + (snapBottom ? 40 : 0)) : Qt.vector4d(0, 0, 0, 0)

    x: horizontal ? Math.max(margin, Math.min(parent.width - panel.width - margin, anchorY - panel.width / 2)) : mirrored ? parent.width - barEdge - width : barEdge
    y: horizontal ? barEdge : snapTop ? bandT : snapBottom ? parent.height - bandT - targetH : rawY
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

    // position only animates while the panel is out; a hidden panel snaps
    Behavior on y {
        enabled: !root.horizontal && (!root.frame || root.shown)
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
        if (retracting && id !== loaded) {
            pendingId = id;
            pendingY = y;
            return;
        }
        pendingId = "";
        snapping = !shown;
        anchorY = y;
        loaded = id;
        snapping = false;
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
        closeGrace.stop();
        pendingId = "";
        current = "";
        shortcutActive = false;
        keyboardOpened = false;
    }

    // the pointer left an entry but is still on the bar: survive the 1 px
    // gap to the next entry, but crossing a spacer retracts the panel
    function closeSoon(): void {
        if (shown)
            closeGrace.restart();
    }

    function contains(px: real, py: real): bool {
        return shown && px >= x && px < x + width && py >= y && py < y + height;
    }

    Timer {
        id: closeGrace

        interval: 120
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
                duration: root.shown ? Theme.spatialDuration : Config.animDuration
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
            // content swapped while the panel is out fades in as it morphs
            onLoaded: {
                if (root.shown)
                    contentFade.restart();
            }
        }

        NumberAnimation {
            id: contentFade

            target: loader
            property: "opacity"
            from: 0
            to: 1
            duration: Config.animDuration
            easing.type: Easing.OutCubic
        }
    }
}
