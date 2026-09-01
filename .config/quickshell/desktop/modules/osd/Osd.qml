import QtQuick
import Quickshell.Hyprland
import "../../config"
import "../../services"
import "../../components"

// Volume / microphone / brightness indicator. Volume changes show on the
// focused monitor; brightness shows on the monitor being adjusted.
Item {
    id: root

    required property HyprlandMonitor monitor
    required property string screenName

    property string icon: ""
    property real value: 0
    property bool muted: false
    property bool shown: false
    property bool ready: false
    property bool suppressed: false   // a popout with its own sliders is open

    readonly property bool focused: monitor?.focused ?? false

    function show(icon: string, value: real, muted: bool): void {
        if (!ready || suppressed)
            return;
        root.icon = icon;
        root.value = value;
        root.muted = muted;
        shown = true;
        hide.restart();
    }

    function volumeIcon(): string {
        if (Audio.muted)
            return "volume_off";
        return Audio.volume > 0.5 ? "volume_up" : Audio.volume > 0 ? "volume_down" : "volume_mute";
    }

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: shown ? 40 : 0
    width: 320
    height: 52
    opacity: shown ? 1 : 0
    visible: opacity > 0

    Behavior on anchors.bottomMargin {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Config.animDurationFast
        }
    }

    Timer {
        id: hide

        interval: Config.osd.hideDelay
        onTriggered: root.shown = false
    }

    // ignore the values that arrive while services initialise
    Timer {
        interval: 1500
        running: true
        onTriggered: root.ready = true
    }

    Connections {
        target: Audio

        function onVolumeChanged(): void {
            if (root.focused)
                root.show(root.volumeIcon(), Audio.volume, Audio.muted);
        }

        function onMutedChanged(): void {
            if (root.focused)
                root.show(root.volumeIcon(), Audio.volume, Audio.muted);
        }

        function onSourceVolumeChanged(): void {
            if (root.focused)
                root.show(Audio.sourceMuted ? "mic_off" : "mic", Audio.sourceVolume, Audio.sourceMuted);
        }

        function onSourceMutedChanged(): void {
            if (root.focused)
                root.show(Audio.sourceMuted ? "mic_off" : "mic", Audio.sourceVolume, Audio.sourceMuted);
        }
    }

    Connections {
        target: Brightness

        function onChanged(name: string, value: real): void {
            const mine = name === root.screenName || (name === "internal" && root.focused);
            if (mine)
                root.show(value > 0.66 ? "brightness_high" : value > 0.33 ? "brightness_medium" : "brightness_low", value, false);
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Colours.alpha(Colours.surfaceContainer, 0.96)
        border.width: 1
        border.color: Colours.alpha(Colours.outlineVariant, 0.5)

        Row {
            anchors.centerIn: parent
            spacing: 14

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: root.icon
                color: root.muted ? Colours.outline : Colours.primary
                fill: true
            }

            Slider {
                anchors.verticalCenter: parent.verticalCenter
                width: 190
                value: root.value
                interactive: false
                accent: root.muted ? Colours.outline : Colours.primary
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                width: 40
                horizontalAlignment: Text.AlignRight
                text: Math.round(root.value * 100) + "%"
                font.family: Config.fontFamilyMono
                color: root.muted ? Colours.outline : Colours.surfaceText
            }
        }
    }
}
