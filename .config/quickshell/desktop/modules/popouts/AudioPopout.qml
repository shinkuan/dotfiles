import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import "../../config"
import "../../services"
import "../../components"

ColumnLayout {
    id: root

    property bool outputOpen: false
    property bool inputOpen: false

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

    // current device row; the full list folds out below it
    component DevicePicker: ColumnLayout {
        id: picker

        property list<PwNode> nodes: []
        property PwNode current: null
        property string fallbackIcon: ""
        property string emptyText: ""
        property bool open: false

        signal picked(PwNode node)

        Layout.fillWidth: true
        spacing: 2

        function scrollToCurrent(): void {
            for (let i = 0; i < nodes.length; i++)
                if (nodes[i] === current)
                    list.positionViewAtIndex(i, ListView.Contain);
        }

        onOpenChanged: {
            if (open)
                scrollToCurrent();
        }

        DisclosureRow {
            icon: picker.current ? Audio.iconFor(picker.current) : picker.fallbackIcon
            title: picker.current ? Audio.displayName(picker.current) : picker.emptyText
            detail: picker.nodes.length > 1 ? `${picker.nodes.length}` : ""
            open: picker.open
            disabled: picker.nodes.length < 2
            onClicked: picker.open = !picker.open
        }

        Collapsible {
            open: picker.open

            ListView {
                id: list

                Layout.fillWidth: true
                implicitHeight: Math.min(count, 6) * 30
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: picker.nodes
                onCountChanged: {
                    if (picker.open)
                        picker.scrollToCurrent();
                }

                delegate: Clickable {
                    id: row

                    required property PwNode modelData
                    readonly property bool active: modelData === picker.current

                    width: ListView.view.width
                    height: 30
                    radius: Theme.radiusItem
                    baseColor: active ? Theme.activeFill : "transparent"
                    onClicked: picker.picked(modelData)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        MaterialIcon {
                            text: Audio.iconFor(row.modelData)
                            font.pixelSize: Config.iconSize - 4
                            color: row.active ? Theme.activeIcon : Colours.surfaceVariantText
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: Audio.displayName(row.modelData)
                            font.pixelSize: Config.fontSize - 1
                            font.weight: row.active ? Font.DemiBold : Font.Normal
                            color: row.active ? Theme.activeText : Colours.surfaceText
                        }

                        MaterialIcon {
                            visible: row.active
                            text: "check"
                            font.pixelSize: Config.iconSize - 4
                            color: Theme.activeIcon
                        }
                    }
                }
            }
        }
    }

    SectionLabel {
        text: "Output"
    }

    VolumeRow {
        node: Audio.sink
        icon: Audio.muted ? "volume_off" : "volume_up"
    }

    DevicePicker {
        nodes: Audio.sinks
        current: Audio.sink
        fallbackIcon: "speaker"
        emptyText: "No output"
        open: root.outputOpen
        onOpenChanged: root.outputOpen = open
        onPicked: node => {
            Audio.setSink(node);
            root.outputOpen = false;
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

    DevicePicker {
        nodes: Audio.sources
        current: Audio.source
        fallbackIcon: "mic"
        emptyText: "No input"
        open: root.inputOpen
        onOpenChanged: root.inputOpen = open
        onPicked: node => {
            Audio.setSource(node);
            root.inputOpen = false;
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
