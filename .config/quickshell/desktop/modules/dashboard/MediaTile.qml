import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
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

    // the album's own colours wash the empty lower part of the tile
    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: -root.pad
        height: root.height * 0.55
        visible: art.status === Image.Ready
        opacity: 0.35

        Image {
            anchors.fill: parent
            source: art.source
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize: Qt.size(64, 64)
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1
                blurMax: 64
            }
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: Colours.surfaceContainer }
                GradientStop { position: 0.7; color: Colours.alpha(Colours.surfaceContainer, 0.2) }
                GradientStop { position: 1; color: Colours.alpha(Colours.surfaceContainer, 0.6) }
            }
        }
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 4

        Ring {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 6
            implicitWidth: 128
            implicitHeight: 128
            thickness: 4
            value: root.has && root.player.lengthSupported && root.player.length > 0 ? root.player.position / root.player.length : 0
            track: Colours.surfaceContainerHighest
            fill: Theme.accent

            ClippingRectangle {
                anchors.centerIn: parent
                width: 104
                height: 104
                radius: 34
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

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: 12
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
            text: [root.player?.trackArtist, root.player?.trackAlbum].filter(t => t).join("  ·  ") || "Unknown artist"
            color: Colours.surfaceVariantText
            font.pixelSize: Config.fontSize - 1
            elide: Text.ElideRight
        }

        // thin position bar with the times at its ends
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 10
            visible: root.has && root.player.lengthSupported
            spacing: 8

            StyledText {
                text: root.has ? root.fmt(root.player.position) : ""
                font.family: Config.fontFamilyMono
                font.pixelSize: Config.fontSize - 3
                color: Colours.outline
            }

            Rectangle {
                Layout.fillWidth: true
                height: 3
                radius: 1.5
                color: Colours.surfaceContainerHighest

                Rectangle {
                    width: root.has && root.player.length > 0 ? parent.width * Math.min(1, root.player.position / root.player.length) : 0
                    height: parent.height
                    radius: parent.radius
                    color: Theme.accent
                }
            }

            StyledText {
                text: root.has ? root.fmt(root.player.length) : ""
                font.family: Config.fontFamilyMono
                font.pixelSize: Config.fontSize - 3
                color: Colours.outline
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 10
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

    }

    function fmt(secs: real): string {
        if (!isFinite(secs) || secs < 0)
            return "0:00";
        const m = Math.floor(secs / 60), s = Math.floor(secs % 60);
        return `${m}:${s < 10 ? "0" : ""}${s}`;
    }
}
