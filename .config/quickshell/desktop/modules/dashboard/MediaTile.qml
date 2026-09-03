import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Mpris
import "../../config"
import "../../services"
import "../../components"

// Album art inside a progress ring, track info, transport controls.
DashTile {
    id: root

    property MprisPlayer player: Players.active
    readonly property bool has: player !== null

    Timer {
        interval: 1000
        running: root.has && root.player.isPlaying
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        Item {
            Layout.preferredHeight: 4
        }

        Ring {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 144
            implicitHeight: 144
            thickness: 4
            value: root.has && root.player.lengthSupported && root.player.length > 0 ? root.player.position / root.player.length : 0
            track: Colours.surfaceContainerHighest
            fill: Theme.accent

            ClippingRectangle {
                anchors.centerIn: parent
                width: 116
                height: 116
                radius: 40
                color: Colours.surfaceContainerHighest

                Image {
                    id: art

                    anchors.fill: parent
                    source: root.player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize: Qt.size(232, 232)
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    visible: art.status !== Image.Ready
                    text: root.has ? "album" : "music_off"
                    color: Colours.surfaceVariantText
                    font.pixelSize: Config.iconSize + 22
                }
            }
        }

        Item {
            Layout.preferredHeight: 6
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: root.has ? (root.player.trackTitle || "Unknown title") : "Nothing playing"
            font.pixelSize: Config.fontSize + 2
            font.weight: Font.DemiBold
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            color: root.has ? Colours.surfaceText : Colours.surfaceVariantText
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.has
            horizontalAlignment: Text.AlignHCenter
            text: root.player?.trackAlbum || "Unknown album"
            color: Colours.surfaceVariantText
            elide: Text.ElideRight
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.has
            horizontalAlignment: Text.AlignHCenter
            text: root.player?.trackArtist || "Unknown artist"
            color: Colours.surfaceVariantText
            elide: Text.ElideRight
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.has && root.player.lengthSupported
            horizontalAlignment: Text.AlignHCenter
            text: root.has ? `${root.fmt(root.player.position)} / ${root.fmt(root.player.length)}` : ""
            font.family: Config.fontFamilyMono
            font.pixelSize: Config.fontSize - 2
            color: Colours.outline
        }

        Item {
            Layout.fillHeight: true
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            IconButton {
                icon: "skip_previous"
                size: 44
                iconSize: Config.iconSize + 4
                disabled: !(root.player?.canGoPrevious ?? false)
                onClicked: root.player.previous()
            }

            Clickable {
                implicitWidth: 76
                implicitHeight: 44
                radius: 22
                disabled: !(root.player?.canTogglePlaying ?? false)
                baseColor: disabled ? Colours.surfaceContainerHighest : Theme.accent
                hoverColor: Colours.alpha(Theme.accent, 0.85)
                pressColor: Colours.alpha(Theme.accent, 0.7)
                onClicked: root.player.togglePlaying()

                MaterialIcon {
                    anchors.centerIn: parent
                    text: root.player?.isPlaying ? "pause" : "play_arrow"
                    fill: true
                    color: parent.disabled ? Colours.surfaceVariantText : Theme.accentText
                    font.pixelSize: Config.iconSize + 8
                }
            }

            IconButton {
                icon: "skip_next"
                size: 44
                iconSize: Config.iconSize + 4
                disabled: !(root.player?.canGoNext ?? false)
                onClicked: root.player.next()
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            visible: (root.player?.shuffleSupported ?? false) || (root.player?.loopSupported ?? false)
            spacing: 18

            IconButton {
                visible: root.player?.shuffleSupported ?? false
                icon: "shuffle"
                checked: root.player?.shuffle ?? false
                onClicked: root.player.shuffle = !root.player.shuffle
            }

            IconButton {
                visible: root.player?.loopSupported ?? false
                icon: root.player?.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
                checked: (root.player?.loopState ?? MprisLoopState.None) !== MprisLoopState.None
                onClicked: {
                    const order = [MprisLoopState.None, MprisLoopState.Playlist, MprisLoopState.Track];
                    root.player.loopState = order[(order.indexOf(root.player.loopState) + 1) % order.length];
                }
            }
        }

        Item {
            Layout.preferredHeight: 2
        }
    }

    function fmt(secs: real): string {
        if (!isFinite(secs) || secs < 0)
            return "0:00";
        const m = Math.floor(secs / 60), s = Math.floor(secs % 60);
        return `${m}:${s < 10 ? "0" : ""}${s}`;
    }
}
