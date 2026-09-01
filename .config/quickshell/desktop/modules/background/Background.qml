import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../config"
import "../../services"

PanelWindow {
    id: root

    WlrLayershell.namespace: "desktop-background"
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: Colours.surface
    mask: Region {}

    Image {
        anchors.fill: parent
        source: Wallpaper.path ? "file://" + Wallpaper.path : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        sourceSize: Qt.size(root.screen.width, root.screen.height)
    }
}
