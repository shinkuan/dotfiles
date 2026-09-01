import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../config"
import "../../services"

// Four invisible 1x1 windows reserve the border ring (and the bar, when
// pinned) via exclusive zones; the main surface ignores exclusion itself.
Scope {
    id: root

    required property ShellScreen screen

    EdgeZone {
        anchors.left: true
        exclusiveZone: BarState.pinned ? Config.barWidth : Config.borderThickness
    }

    EdgeZone {
        anchors.top: true
    }

    EdgeZone {
        anchors.right: true
    }

    EdgeZone {
        anchors.bottom: true
    }

    component EdgeZone: PanelWindow {
        screen: root.screen
        WlrLayershell.namespace: "desktop-edge"
        WlrLayershell.layer: WlrLayer.Top
        exclusiveZone: Config.borderThickness
        color: "transparent"
        mask: Region {}
        implicitWidth: 1
        implicitHeight: 1
    }
}
