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
// border ring, the bar and whatever is currently expanded; everything else
// clicks through to the windows below. All hover decisions are made here,
// from one HoverHandler, by geometry. (A hover-enabled MouseArea cannot be
// used for this: any HoverHandler above it steals its hover.)
PanelWindow {
    id: root

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
    readonly property bool hasFullscreen: monitor?.activeWorkspace?.hasFullscreen ?? false
    property bool barHovered: false
    readonly property real interactiveLeft: bar.revealed ? Config.barWidth : Config.borderThickness

    WlrLayershell.namespace: "desktop-shell"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: popouts.shortcutActive ? WlrKeyboardFocus.Exclusive : (popouts.needsKeyboard && popouts.shown) || (notifPopups.visible && notifPopups.needsKeyboard) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

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
            x: root.interactiveLeft
            y: Config.borderThickness
            width: root.width - x - Config.borderThickness
            height: root.height - Config.borderThickness * 2
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

    function handleDrag(pressX: real, dx: real): void {
        if (!ShellState.barPinned && pressX <= root.interactiveLeft && dx > Config.barPinThreshold)
            ShellState.set("barPinned", true);
        else if (ShellState.barPinned && pressX <= Config.barWidth && dx < -Config.barPinThreshold)
            ShellState.set("barPinned", false);
    }

    function handleHover(x: real, y: real): void {
        if (root.hasFullscreen)
            return;
        leaveGrace.stop();
        const inBar = x <= root.interactiveLeft;
        root.barHovered = inBar;
        if (inBar) {
            const hit = bar.popoutAt(y);
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
        onPressed: mouse => pressX = mouse.x
        onReleased: pressX = -1
        onPositionChanged: mouse => {
            if (pressX >= 0)
                root.handleDrag(pressX, mouse.x - pressX);
        }
    }

    Bar {
        id: bar

        monitor: root.monitor
        revealed: !root.hasFullscreen && (ShellState.barPinned || root.barHovered || popouts.shown)
        activePopout: popouts.current
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        onDragged: dx => root.handleDrag(0, dx)
        onItemClicked: (id, y) => popouts.openShortcut(id, y)
    }

    Popouts {
        id: popouts

        monitor: root.monitor
        barEdge: bar.exposedWidth
    }

    Osd {
        monitor: root.monitor
        screenName: root.screen.name
    }

    KGridOsd {
        monitor: root.monitor
    }

    NotifPopups {
        id: notifPopups

        monitor: root.monitor
    }

    // shortcut-opened popouts stay until Esc or a click outside the shell
    Item {
        focus: popouts.shortcutActive
        Keys.onEscapePressed: popouts.close()
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
            if (root.monitor?.focused)
                popouts.openShortcut(id, bar.anchorFor(id));
        }

        function onSession(): void {
            if (root.monitor?.focused)
                popouts.openShortcut("power", bar.anchorFor("power"));
        }

        function onClosePopouts(): void {
            popouts.close();
        }
    }
}
