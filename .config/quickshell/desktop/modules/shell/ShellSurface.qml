import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../config"
import "../../services"
import "../bar"

// Full-screen top layer that never reserves space. Input only lands on the
// border ring plus whatever is currently expanded (Xor'd interior rect);
// everything else clicks through to the windows below.
PanelWindow {
    id: root

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
    readonly property bool hasFullscreen: monitor?.activeWorkspace?.hasFullscreen ?? false
    property bool barHovered: false
    readonly property real interactiveLeft: Math.max(bar.exposedWidth, Config.borderThickness)

    WlrLayershell.namespace: "desktop-shell"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    mask: hasFullscreen ? passthrough : ring

    onHasFullscreenChanged: if (hasFullscreen) barHovered = false

    Region {
        id: passthrough
    }

    Region {
        id: ring

        x: root.interactiveLeft
        y: Config.borderThickness
        width: root.width - x - Config.borderThickness
        height: root.height - Config.borderThickness * 2
        intersection: Intersection.Xor
    }

    MouseArea {
        id: tracker

        property real pressX: -1

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: root.hasFullscreen ? Qt.NoButton : Qt.LeftButton

        onPressed: mouse => pressX = mouse.x
        onReleased: pressX = -1
        onExited: root.barHovered = false
        onPositionChanged: mouse => {
            if (root.hasFullscreen)
                return;
            root.barHovered = mouse.x <= root.interactiveLeft;
            if (pressX < 0)
                return;
            const dx = mouse.x - pressX;
            if (!BarState.pinned && pressX <= root.interactiveLeft && dx > Config.barPinThreshold)
                BarState.setPinned(true);
            else if (BarState.pinned && pressX <= Config.barWidth && dx < -Config.barPinThreshold)
                BarState.setPinned(false);
        }
    }

    Bar {
        id: bar

        monitor: root.monitor
        revealed: !root.hasFullscreen && (BarState.pinned || root.barHovered)
        anchors.top: parent.top
        anchors.bottom: parent.bottom
    }
}
