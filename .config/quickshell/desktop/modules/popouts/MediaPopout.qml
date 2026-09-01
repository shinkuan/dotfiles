import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Mpris
import "../../config"
import "../../services"
import "../../components"

ColumnLayout {
    id: root

    property MprisPlayer player: Players.active

    width: Config.popouts.width
    spacing: 10

    function fmt(secs: real): string {
        if (!isFinite(secs) || secs < 0)
            return "0:00";
        const m = Math.floor(secs / 60), s = Math.floor(secs % 60);
        return `${m}:${s < 10 ? "0" : ""}${s}`;
    }

    // Mpris position only advances on demand
    Timer {
        interval: 1000
        running: root.player !== null && root.player.isPlaying
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    Flow {
        Layout.fillWidth: true
        visible: Players.players.length > 1
        spacing: 6

        Repeater {
            model: Players.players

            Chip {
                required property MprisPlayer modelData

                text: modelData.identity
                checked: root.player === modelData
                onClicked: root.player = modelData
            }
        }
    }

    StyledText {
        visible: root.player === null
        text: "No media player"
        color: Colours.surfaceVariantText
    }

    RowLayout {
        visible: root.player !== null
        Layout.fillWidth: true
        spacing: 14

        ClippingRectangle {
            implicitWidth: 96
            implicitHeight: 96
            radius: Config.radius
            color: Colours.surfaceContainerHighest

            Image {
                id: art

                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize: Qt.size(192, 192)
            }

            MaterialIcon {
                anchors.centerIn: parent
                visible: art.status !== Image.Ready
                text: "album"
                color: Colours.surfaceVariantText
                font.pixelSize: Config.iconSize + 14
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                text: root.player?.trackTitle || "Unknown title"
                font.pixelSize: Config.fontSize + 2
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
                maximumLineCount: 2
            }

            StyledText {
                Layout.fillWidth: true
                text: root.player?.trackArtist ?? ""
                color: Colours.surfaceVariantText
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.player?.trackAlbum ?? ""
                color: Colours.outline
                font.pixelSize: Config.fontSize - 1
            }

            StyledText {
                Layout.fillWidth: true
                text: root.player?.identity ?? ""
                color: Colours.outline
                font.pixelSize: Config.fontSize - 2
            }
        }
    }

    RowLayout {
        visible: root.player !== null && root.player.lengthSupported
        Layout.fillWidth: true
        spacing: 8

        StyledText {
            text: root.fmt(root.player?.position ?? 0)
            font.family: Config.fontFamilyMono
            font.pixelSize: Config.fontSize - 2
            color: Colours.surfaceVariantText
        }

        Slider {
            Layout.fillWidth: true
            value: root.player && root.player.length > 0 ? root.player.position / root.player.length : 0
            interactive: root.player?.canSeek ?? false
            onMoved: v => {
                if (root.player)
                    root.player.position = v * root.player.length;
            }
        }

        StyledText {
            text: root.fmt(root.player?.length ?? 0)
            font.family: Config.fontFamilyMono
            font.pixelSize: Config.fontSize - 2
            color: Colours.surfaceVariantText
        }
    }

    RowLayout {
        visible: root.player !== null
        Layout.alignment: Qt.AlignHCenter
        spacing: 12

        IconButton {
            icon: "shuffle"
            checked: root.player?.shuffle ?? false
            disabled: !(root.player?.shuffleSupported ?? false)
            onClicked: root.player.shuffle = !root.player.shuffle
        }

        IconButton {
            icon: "skip_previous"
            size: 40
            iconSize: Config.iconSize + 4
            disabled: !(root.player?.canGoPrevious ?? false)
            onClicked: root.player.previous()
        }

        IconButton {
            icon: root.player?.isPlaying ? "pause" : "play_arrow"
            fill: true
            size: 52
            iconSize: Config.iconSize + 10
            checked: true
            disabled: !(root.player?.canTogglePlaying ?? false)
            onClicked: root.player.togglePlaying()
        }

        IconButton {
            icon: "skip_next"
            size: 40
            iconSize: Config.iconSize + 4
            disabled: !(root.player?.canGoNext ?? false)
            onClicked: root.player.next()
        }

        IconButton {
            icon: root.player?.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
            checked: (root.player?.loopState ?? MprisLoopState.None) !== MprisLoopState.None
            disabled: !(root.player?.loopSupported ?? false)
            onClicked: {
                const order = [MprisLoopState.None, MprisLoopState.Playlist, MprisLoopState.Track];
                root.player.loopState = order[(order.indexOf(root.player.loopState) + 1) % order.length];
            }
        }
    }
}
