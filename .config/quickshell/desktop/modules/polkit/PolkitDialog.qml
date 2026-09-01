import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Polkit
import "../../config"
import "../../services"
import "../../components"

// Authentication prompt for the shell's polkit agent, on the focused monitor.
PanelWindow {
    id: root

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
    readonly property bool active: Polkit.active && (monitor?.focused ?? false)
    readonly property AuthFlow flow: Polkit.flow

    visible: active
    WlrLayershell.namespace: "desktop-polkit"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: Colours.alpha(Colours.scrim, 0.4)

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    onActiveChanged: {
        if (active) {
            input.text = "";
            input.forceActiveFocus();
        }
    }

    Connections {
        target: root.flow

        function onIsResponseRequiredChanged(): void {
            if (root.flow.isResponseRequired) {
                input.text = "";
                input.forceActiveFocus();
            }
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 440
        height: column.implicitHeight + 48
        radius: Config.radiusLarge
        color: Colours.surfaceContainer
        border.width: 1
        border.color: Colours.alpha(Colours.outlineVariant, 0.5)

        ColumnLayout {
            id: column

            anchors.fill: parent
            anchors.margins: 24
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                Rectangle {
                    width: 48
                    height: 48
                    radius: 24
                    color: Colours.alpha(Colours.primary, 0.15)

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "lock"
                        color: Colours.primary
                        fill: true
                        font.pixelSize: Config.iconSize + 4
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        Layout.fillWidth: true
                        text: "Authentication required"
                        font.pixelSize: Config.fontSize + 3
                        font.weight: Font.DemiBold
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.flow?.message ?? ""
                        color: Colours.surfaceVariantText
                        wrapMode: Text.Wrap
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: (root.flow?.actionId ?? "") !== ""
                text: root.flow?.actionId ?? ""
                color: Colours.outline
                font.family: Config.fontFamilyMono
                font.pixelSize: Config.fontSize - 2
                elide: Text.ElideMiddle
            }

            Flow {
                Layout.fillWidth: true
                visible: (root.flow?.identities.length ?? 0) > 1
                spacing: 6

                Repeater {
                    model: root.flow?.identities ?? []

                    Chip {
                        required property var modelData

                        icon: "person"
                        text: modelData.displayName ?? modelData.name ?? String(modelData)
                        checked: root.flow.selectedIdentity === modelData
                        onClicked: root.flow.selectedIdentity = modelData
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 42
                radius: Config.radius
                color: Colours.surfaceContainerHighest
                border.width: input.activeFocus ? 2 : 0
                border.color: Colours.primary

                TextInput {
                    id: input

                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    color: Colours.surfaceText
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize + 1
                    echoMode: root.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                    enabled: root.flow?.isResponseRequired ?? false
                    onAccepted: root.flow.submit(text)
                    Keys.onEscapePressed: root.flow.cancelAuthenticationRequest()

                    StyledText {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        visible: !input.text
                        text: root.flow?.inputPrompt || "Password"
                        color: Colours.outline
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.flow?.supplementaryMessage ?? ""
                color: root.flow?.supplementaryIsError ? Colours.error : Colours.surfaceVariantText
                wrapMode: Text.Wrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item {
                    Layout.fillWidth: true
                }

                Chip {
                    text: "Cancel"
                    onClicked: root.flow.cancelAuthenticationRequest()
                }

                Chip {
                    icon: "check"
                    text: "Authenticate"
                    checked: true
                    onClicked: root.flow.submit(input.text)
                }
            }
        }
    }
}
