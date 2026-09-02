import QtQuick
import Quickshell.Widgets
import Quickshell.Services.Mpris
import "../../config"
import "../../services"
import "../../components"

// Now-playing entry; only present while a player exists.
BarItem {
    id: root

    readonly property MprisPlayer player: Players.active

    popout: "media"
    visible: player !== null

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        width: Config.iconSize + 2
        height: Config.iconSize + 2

        ClippingRectangle {
            anchors.fill: parent
            radius: 6
            color: "transparent"
            visible: art.status === Image.Ready

            Image {
                id: art

                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize: Qt.size(48, 48)
            }
        }

        MaterialIcon {
            anchors.centerIn: parent
            visible: art.status !== Image.Ready
            text: root.player?.isPlaying ? "music_note" : "pause_circle"
            color: root.player?.isPlaying ? Theme.accent : Colours.surfaceVariantText
        }
    }

    WheelHandler {
        onWheel: e => {
            if (!root.player)
                return;
            if (e.angleDelta.y > 0 && root.player.canGoPrevious)
                root.player.previous();
            else if (e.angleDelta.y < 0 && root.player.canGoNext)
                root.player.next();
        }
    }

    onClicked: m => {
        if (m.button === Qt.MiddleButton && root.player?.canTogglePlaying)
            root.player.togglePlaying();
    }
}
