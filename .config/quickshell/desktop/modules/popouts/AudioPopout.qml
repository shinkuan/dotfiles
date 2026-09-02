import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import "../../config"
import "../../services"
import "../../components"

ColumnLayout {
    id: root

    width: Config.popouts.width
    spacing: 6

    component VolumeRow: RowLayout {
        id: vrow

        required property PwNode node
        property string icon: ""
        property string label: ""

        Layout.fillWidth: true
        spacing: 8

        IconButton {
            icon: vrow.icon
            iconColor: vrow.node?.audio?.muted ? Colours.outline : Colours.surfaceText
            onClicked: Audio.toggleMute(vrow.node)
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                visible: vrow.label !== ""
                Layout.fillWidth: true
                text: vrow.label
                font.pixelSize: Config.fontSize - 1
                color: Colours.surfaceVariantText
            }

            Slider {
                Layout.fillWidth: true
                value: vrow.node?.audio?.volume ?? 0
                accent: vrow.node?.audio?.muted ? Colours.outline : Theme.accent
                onMoved: v => Audio.setVolume(vrow.node, v)
            }
        }

        StyledText {
            Layout.preferredWidth: 36
            horizontalAlignment: Text.AlignRight
            text: Math.round((vrow.node?.audio?.volume ?? 0) * 100) + "%"
            font.family: Config.fontFamilyMono
            font.pixelSize: Config.fontSize - 1
            color: Colours.surfaceVariantText
        }
    }

    SectionLabel {
        text: "Output"
    }

    VolumeRow {
        node: Audio.sink
        icon: Audio.muted ? "volume_off" : "volume_up"
    }

    Repeater {
        model: Audio.sinks

        ListItem {
            id: sinkItem

            required property PwNode modelData

            Layout.fillWidth: true
            icon: Audio.iconFor(modelData)
            title: Audio.displayName(modelData)
            active: modelData === Audio.sink
            onClicked: Audio.setSink(modelData)

            MaterialIcon {
                visible: sinkItem.active
                text: "check"
                color: Theme.accent
                font.pixelSize: Config.iconSize - 4
            }
        }
    }

    SectionLabel {
        Layout.topMargin: 6
        text: "Input"
    }

    VolumeRow {
        node: Audio.source
        icon: Audio.sourceMuted ? "mic_off" : "mic"
    }

    Repeater {
        model: Audio.sources

        ListItem {
            id: sourceItem

            required property PwNode modelData

            Layout.fillWidth: true
            icon: Audio.iconFor(modelData)
            title: Audio.displayName(modelData)
            active: modelData === Audio.source
            onClicked: Audio.setSource(modelData)

            MaterialIcon {
                visible: sourceItem.active
                text: "check"
                color: Theme.accent
                font.pixelSize: Config.iconSize - 4
            }
        }
    }

    SectionLabel {
        Layout.topMargin: 6
        visible: Audio.streams.length > 0
        text: "Applications"
    }

    Repeater {
        model: Audio.streams

        VolumeRow {
            required property PwNode modelData

            node: modelData
            icon: "graphic_eq"
            label: (modelData.properties?.["application.name"] ?? modelData.name) + (modelData.properties?.["media.name"] ? " · " + modelData.properties["media.name"] : "")
        }
    }
}
