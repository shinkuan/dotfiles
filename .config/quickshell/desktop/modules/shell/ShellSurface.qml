import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../config"
import "../../services"
import "../bar"
import "../popouts"
import "../osd"
import "../notifications"

// Full-screen top layer that never reserves space. Input only lands on the
// left edge band, the bar and whatever is currently expanded; everything
// else clicks through to the windows below. All hover decisions are made here,
// from one HoverHandler, by geometry. (A hover-enabled MouseArea cannot be
// used for this: any HoverHandler above it steals its hover.)
PanelWindow {
    id: root

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
    readonly property bool hasFullscreen: monitor?.activeWorkspace?.hasFullscreen ?? false
    property bool barHovered: false
    readonly property bool barTop: Theme.barTop
    readonly property bool barRight: Theme.barRight
    readonly property real interactiveLeft: bar.revealed && !barTop ? Config.barWidth : Config.borderThickness
    readonly property real interactiveTop: bar.revealed && barTop ? Config.barWidth : Config.borderThickness

    WlrLayershell.namespace: "desktop-shell"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    // keyboard-opened popouts own the keyboard (Esc closes them); clicked or
    // hovered ones only take it on demand for their text fields
    WlrLayershell.keyboardFocus: popouts.keyboardOpened ? WlrKeyboardFocus.Exclusive : popouts.shortcutActive || (popouts.needsKeyboard && popouts.shown) || (notifPopups.visible && notifPopups.needsKeyboard) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    // fullscreen: nothing but the notification popups may take input
    mask: hasFullscreen ? (notifPopups.visible ? popupsOnly : passthrough) : interactive

    onHasFullscreenChanged: {
        if (hasFullscreen) {
            barHovered = false;
            popouts.close();
        }
    }

    Region {
        id: passthrough
    }

    Region {
        id: popupsOnly

        x: notifPopups.x
        y: notifPopups.y
        width: notifPopups.width
        height: notifPopups.height
    }

    Region {
        id: interactive

        x: 0
        y: 0
        width: root.width
        height: root.height

        Region {
            x: root.barTop || root.barRight ? 0 : root.interactiveLeft
            y: root.barTop ? root.interactiveTop : 0
            width: root.barRight ? root.width - root.interactiveLeft : root.width - x
            height: root.height - y
            intersection: Intersection.Xor
        }

        Region {
            x: popouts.x
            y: popouts.y
            width: popouts.width
            height: popouts.height
            intersection: Intersection.Combine
        }

        Region {
            x: notifPopups.x
            y: notifPopups.y
            width: notifPopups.visible ? notifPopups.width : 0
            height: notifPopups.visible ? notifPopups.height : 0
            intersection: Intersection.Combine
        }
    }

    // press / delta are measured from the bar's own edge inward
    function handleDrag(press: real, delta: real): void {
        const edge = root.barTop ? root.interactiveTop : root.interactiveLeft;
        if (!ShellState.barPinned && press <= edge && delta > Config.barPinThreshold)
            ShellState.set("barPinned", true);
        else if (ShellState.barPinned && press <= Theme.barSpan && delta < -Config.barPinThreshold)
            ShellState.set("barPinned", false);
    }

    function edgeCoord(mouse): real {
        return root.barTop ? mouse.y : root.barRight ? root.width - mouse.x : mouse.x;
    }

    function handleHover(x: real, y: real): void {
        if (root.hasFullscreen)
            return;
        leaveGrace.stop();
        const inBar = root.barTop ? y <= root.interactiveTop : root.barRight ? x >= root.width - root.interactiveLeft : x <= root.interactiveLeft;
        root.barHovered = inBar;
        if (inBar) {
            const hit = bar.popoutAt(root.barTop ? x : y);
            if (hit && Config.popouts.showOnHover && !popouts.shortcutActive)
                popouts.open(hit.id, hit.y);
            else if (!hit && !popouts.shortcutActive)
                popouts.close();
        } else if (!popouts.contains(x, y) && !popouts.shortcutActive) {
            popouts.close();
        }
    }

    HoverHandler {
        id: tracker

        readonly property point pos: point.position

        enabled: !root.hasFullscreen
        onPosChanged: {
            if (hovered)
                root.handleHover(pos.x, pos.y);
        }
        onHoveredChanged: {
            if (hovered)
                root.handleHover(pos.x, pos.y);
            else
                leaveGrace.restart();
        }
    }

    // a leave immediately followed by a re-enter (mask edits, 1px gaps) must
    // not collapse anything
    Timer {
        id: leaveGrace

        interval: 120
        onTriggered: {
            root.barHovered = false;
            if (!popouts.shortcutActive)
                popouts.close();
        }
    }

    MouseArea {
        property real pressX: -1

        anchors.fill: parent
        acceptedButtons: root.hasFullscreen ? Qt.NoButton : Qt.LeftButton
        onPressed: mouse => pressX = root.edgeCoord(mouse)
        onReleased: pressX = -1
        onPositionChanged: mouse => {
            if (pressX >= 0)
                root.handleDrag(pressX, root.edgeCoord(mouse) - pressX);
        }
    }

    Bar {
        id: bar

        monitor: root.monitor
        revealed: !root.hasFullscreen && (ShellState.barPinned || root.barHovered || popouts.shown)
        activePopout: popouts.current
        onDragged: dx => root.handleDrag(0, root.barRight ? -dx : dx)
        onItemClicked: (id, y) => popouts.openShortcut(id, y, false)
    }

    Popouts {
        id: popouts

        monitor: root.monitor
        barEdge: bar.exposedWidth
    }

    Osd {
        monitor: root.monitor
        screenName: root.screen.name
        suppressed: popouts.shown
    }

    KGridOsd {
        monitor: root.monitor
    }

    NotifPopups {
        id: notifPopups

        monitor: root.monitor
    }

    // shortcut-opened popouts stay until Esc or a click outside the shell
    Shortcut {
        sequences: ["Escape"]
        enabled: popouts.shortcutActive
        onActivated: popouts.close()
    }

    // the grab is armed a moment after the layer takes keyboard focus;
    // arming it while an app still holds focus clears it instantly
    Timer {
        id: grabDelay

        interval: 150
        onTriggered: grab.active = popouts.shortcutActive
    }

    Connections {
        target: popouts

        function onShortcutActiveChanged(): void {
            if (popouts.shortcutActive)
                grabDelay.restart();
            else
                grab.active = false;
        }
    }

    HyprlandFocusGrab {
        id: grab

        windows: [root]
        onCleared: {
            if (popouts.shortcutActive)
                popouts.close();
        }
    }

    Connections {
        target: Requests

        function onPopout(id: string): void {
            if (root.monitor?.focused && !root.hasFullscreen)
                popouts.openShortcut(id, bar.anchorFor(id), true);
        }

        function onSession(): void {
            if (root.monitor?.focused && !root.hasFullscreen)
                popouts.openShortcut("power", bar.anchorFor("power"), true);
        }

        function onClosePopouts(): void {
            popouts.close();
        }
    }
}
