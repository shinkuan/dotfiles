import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../config"
import "../../services"
import "../../components"
import "../popouts"

// Full-screen overlay on the focused monitor; the deck scales out of the
// pointer position (flipping to stay on screen) or the screen centre.
PanelWindow {
    id: root

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
    readonly property bool active: Summon.open && (monitor?.focused ?? false)
    property bool closing: false

    readonly property real lx: Summon.x - (monitor?.x ?? 0)
    readonly property real ly: Summon.y - (monitor?.y ?? 0)
    readonly property bool flipX: !Summon.centered && lx + deck.width + 24 > width
    readonly property bool flipY: !Summon.centered && ly + deck.height + 24 > height
    readonly property int gridWidth: KGrid.columns * 52 + (KGrid.columns - 1) * 6   // KGridPopout cell geometry

    visible: active || closing
    WlrLayershell.namespace: "desktop-summon"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    onActiveChanged: {
        if (active) {
            closing = false;
            closeTimer.stop();
        } else {
            closing = true;
            closeTimer.restart();
        }
    }

    Timer {
        id: closeTimer

        interval: 220
        onTriggered: root.closing = false
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.active
        onActivated: Summon.hide()
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Summon.hide()
    }

    Surface {
        id: deck

        readonly property int pad: 18

        x: Summon.centered ? Math.round((root.width - width) / 2) : Math.round(Math.max(8, Math.min(root.width - width - 8, root.flipX ? root.lx - width - 8 : root.lx + 8)))
        y: Summon.centered ? Math.round((root.height - height) / 2) : Math.round(Math.max(8, Math.min(root.height - height - 8, root.flipY ? root.ly - height - 8 : root.ly + 8)))
        width: root.gridWidth + pad * 2 + 18 + 280
        height: body.implicitHeight + pad * 2
        radius: Theme.radius + 8

        transformOrigin: Summon.centered ? Item.Center : root.flipX ? (root.flipY ? Item.BottomRight : Item.TopRight) : (root.flipY ? Item.BottomLeft : Item.TopLeft)
        scale: root.active ? 1 : 0.55
        opacity: root.active ? 1 : 0

        Behavior on scale {
            NumberAnimation {
                duration: root.active ? 350 : 200
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.active ? [0.42, 1.67, 0.21, 0.9, 1, 1] : [0.34, 0.8, 0.34, 1, 1, 1]
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 180
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.34, 0.8, 0.34, 1, 1, 1]
            }
        }

        MouseArea {
            anchors.fill: parent   // swallow clicks so the scrim MouseArea does not close the deck
        }

        ColumnLayout {
            id: body

            x: deck.pad
            y: deck.pad
            width: deck.width - deck.pad * 2
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ColumnLayout {
                    spacing: 0

                    StyledText {
                        text: Qt.formatDateTime(clock.date, "HH:mm")
                        font.family: Theme.fontLabel
                        font.pixelSize: 28
                        font.weight: Font.DemiBold
                    }

                    StyledText {
                        text: Qt.formatDateTime(clock.date, "ddd d MMM")
                        color: Colours.surfaceVariantText
                        font.pixelSize: Config.fontSize - 1
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Chip {
                    icon: Net.activeWifi ? Net.signalIcon(Net.activeWifi.signalStrength ?? 0) : Net.wiredConnected ? "lan" : "wifi_off"
                    text: Net.activeWifi ? (Net.activeWifi.ssid ?? "Wi‑Fi") : Net.wiredConnected ? "Wired" : "Offline"
                }

                Chip {
                    visible: Battery.laptop
                    icon: "battery_5_bar"
                    text: `${Battery.percent}%`
                }

                Chip {
                    icon: Notifs.dnd ? "notifications_off" : "notifications"
                    text: Notifs.dnd ? "Silent" : "Notify"
                    checked: Notifs.dnd
                    onClicked: ShellState.toggle("dnd")
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 18

                KGridPopout {
                    monitor: root.monitor
                    Layout.preferredWidth: root.gridWidth
                    Layout.alignment: Qt.AlignTop
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: 10

                    SliderRow {
                        icon: Audio.muted ? "volume_off" : "volume_up"
                        value: Audio.volume
                        onMoved: v => Audio.setVolume(Audio.sink, v)
                    }

                    SliderRow {
                        readonly property string mon: root.screen.name

                        visible: Brightness.valueFor(mon) >= 0
                        icon: "brightness_6"
                        value: Brightness.valueFor(mon)
                        onMoved: v => Brightness.set(mon, v)
                    }

                    RowLayout {
                        visible: Players.active !== null
                        spacing: 10

                        MaterialIcon {
                            text: "music_note"
                            color: Theme.accent
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                Layout.fillWidth: true
                                text: Players.active?.trackTitle || "Nothing playing"
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: Players.active?.trackArtist ?? ""
                                color: Colours.surfaceVariantText
                                font.pixelSize: Config.fontSize - 2
                            }
                        }

                        IconButton {
                            icon: Players.active?.isPlaying ? "pause" : "play_arrow"
                            fill: true
                            onClicked: Players.active?.togglePlaying()
                        }

                        IconButton {
                            icon: "skip_next"
                            onClicked: Players.active?.next()
                        }
                    }
                }
            }

            Clickable {
                Layout.fillWidth: true
                implicitHeight: 40
                radius: Theme.radiusItem
                baseColor: Theme.panelRaised
                onClicked: {
                    Summon.hide();
                    Launcher.show();
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    MaterialIcon {
                        text: "search"
                        color: Colours.surfaceVariantText
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: "Search apps"
                        color: Colours.surfaceVariantText
                    }

                    StyledText {
                        text: `${Config.launcher.actionPrefix} actions  ·  ${Config.launcher.calcPrefix} calc`
                        color: Colours.surfaceVariantText
                        font.family: Theme.fontMono
                        font.pixelSize: Config.fontSize - 2
                    }
                }
            }
        }
    }

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    component SliderRow: RowLayout {
        id: sliderRow

        property string icon
        property real value
        signal moved(real value)

        Layout.fillWidth: true
        spacing: 10

        MaterialIcon {
            text: sliderRow.icon
            color: Colours.surfaceVariantText
        }

        Slider {
            Layout.fillWidth: true
            value: sliderRow.value
            onMoved: v => sliderRow.moved(v)
        }

        StyledText {
            Layout.preferredWidth: 30
            horizontalAlignment: Text.AlignRight
            text: Math.round(sliderRow.value * 100)
            color: Colours.surfaceVariantText
            font.family: Theme.fontMono
            font.pixelSize: Config.fontSize - 2
        }
    }
}
