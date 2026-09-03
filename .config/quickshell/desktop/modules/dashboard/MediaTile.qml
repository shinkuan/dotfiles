import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import Quickshell.Services.Mpris
import "../../config"
import "../../services"
import "../../components"

// Now playing as one row: art, title, artist and position, transport
// controls, with the album's colours washed across the card.
DashTile {
    id: root

    property MprisPlayer player: Players.active
    readonly property bool has: player !== null

    pad: 14

    Timer {
        interval: 1000
        running: root.has && root.player.isPlaying
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    ClippingRectangle {
        anchors.fill: parent
        anchors.margins: -root.pad
        color: "transparent"
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        bottomRightRadius: root.bottomRightRadius
        visible: art.status === Image.Ready

        Image {
            anchors.fill: parent
            anchors.margins: -24
            source: art.source
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize: Qt.size(64, 64)
            opacity: 0.65
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
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Colours.alpha(Colours.surfaceContainer, 0.1) }
                GradientStop { position: 1; color: Colours.alpha(Colours.surfaceContainer, 0.5) }
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 12

        ClippingRectangle {
            implicitWidth: 64
            implicitHeight: 64
            radius: 12
            color: Colours.surfaceContainerHighest

            Image {
                id: art

                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize: Qt.size(128, 128)
            }

            MaterialIcon {
                anchors.centerIn: parent
                visible: art.status !== Image.Ready
                text: root.has ? "album" : "music_off"
                color: Colours.surfaceVariantText
                font.pixelSize: Config.iconSize + 8
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                text: root.has ? (root.player.trackTitle || "Unknown title") : "Nothing playing"
                font.pixelSize: Config.fontSize + 1
                font.weight: Font.Medium
                elide: Text.ElideRight
                color: root.has ? Colours.surfaceText : Colours.surfaceVariantText
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.has
                text: [root.player?.trackArtist || "Unknown artist", root.player?.lengthSupported ? `${root.fmt(root.player.position)} / ${root.fmt(root.player.length)}` : ""].filter(t => t).join(" · ")
                color: Colours.surfaceVariantText
                font.pixelSize: Config.fontSize - 1
                elide: Text.ElideRight
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 6
                visible: root.has && root.player.lengthSupported
                height: 2
                radius: 1
                color: Colours.alpha(Colours.surfaceText, 0.18)

                Rectangle {
                    width: root.has && root.player.length > 0 ? parent.width * Math.min(1, root.player.position / root.player.length) : 0
                    height: parent.height
                    radius: parent.radius
                    color: Colours.surfaceText
                }
            }
        }

        RowLayout {
            spacing: 2

            IconButton {
                icon: "skip_previous"
                size: 30
                iconSize: Config.iconSize
                iconColor: Colours.surfaceText
                disabled: !(root.player?.canGoPrevious ?? false)
                onClicked: root.player.previous()
            }

            Clickable {
                implicitWidth: 36
                implicitHeight: 36
                radius: 18
                disabled: !(root.player?.canTogglePlaying ?? false)
                baseColor: Colours.alpha(Colours.surfaceText, disabled ? 0.08 : 0.16)
                hoverColor: Colours.alpha(Colours.surfaceText, 0.26)
                pressColor: Colours.alpha(Colours.surfaceText, 0.34)
                onClicked: root.player.togglePlaying()

                MaterialIcon {
                    anchors.centerIn: parent
                    text: root.player?.isPlaying ? "pause" : "play_arrow"
                    fill: true
                    color: parent.disabled ? Colours.surfaceVariantText : Colours.surfaceText
                    font.pixelSize: Config.iconSize + 2
                }
            }

            IconButton {
                icon: "skip_next"
                size: 30
                iconSize: Config.iconSize
                iconColor: Colours.surfaceText
                disabled: !(root.player?.canGoNext ?? false)
                onClicked: root.player.next()
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
