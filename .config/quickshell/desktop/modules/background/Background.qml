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

    // two layers so a wallpaper change crossfades instead of popping
    property bool showA: true

    component WallpaperLayer: Image {
        property bool current: false

        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        sourceSize: Qt.size(root.screen.width, root.screen.height)
        opacity: current && status === Image.Ready ? 1 : 0
        z: current ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Config.animDurationSlow * 2
                easing.type: Easing.InOutQuad
            }
        }
    }

    WallpaperLayer {
        id: layerA

        current: root.showA
    }

    WallpaperLayer {
        id: layerB

        current: !root.showA
    }

    Connections {
        target: Wallpaper

        function onPathChanged(): void {
            root.showWallpaper();
        }
    }

    Component.onCompleted: showWallpaper()

    function showWallpaper(): void {
        if (!Wallpaper.path)
            return;
        const next = showA ? layerB : layerA;
        next.source = "file://" + Wallpaper.path;
        showA = !showA;
    }

    DesktopClock {
        visible: ShellState.desktopClock
    }
}
