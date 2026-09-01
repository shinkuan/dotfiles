import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "../../config"
import "../../services"
import "../../components"

// One notification. `compact` is the history rendering (no reply field,
// smaller image); popups allow swipe-right and middle-click to dismiss.
Rectangle {
    id: root

    required property var entry
    property bool compact: false
    readonly property bool live: entry.notif !== null && entry.notif !== undefined
    readonly property bool critical: entry.urgency === NotificationUrgency.Critical
    readonly property bool replying: replyField.activeFocus
    signal dismissed()
    signal swiped()

    implicitHeight: column.implicitHeight + 24
    radius: Config.radiusLarge - 4
    color: critical ? Colours.mix(Colours.surfaceContainerHigh, Colours.errorContainer, 0.35) : Colours.surfaceContainerHigh
    border.width: critical ? 1 : 0
    border.color: Colours.alpha(Colours.error, 0.6)

    function timeLabel(t: real): string {
        const d = new Date(t);
        const diff = (Date.now() - t) / 60000;
        if (diff < 1)
            return "now";
        if (diff < 60)
            return Math.floor(diff) + "m";
        if (new Date().toDateString() === d.toDateString())
            return Qt.formatTime(d, "HH:mm");
        return Qt.formatDate(d, "d MMM");
    }

    HoverHandler {
        enabled: !root.compact
        onHoveredChanged: Notifs.setHovered(root.entry.id, hovered)
    }

    MouseArea {
        property real pressX: -1

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onPressed: m => pressX = m.x
        onPositionChanged: m => {
            if (pressX >= 0 && !root.compact)
                root.x = Math.max(0, m.x - pressX);
        }
        onReleased: m => {
            if (m.button === Qt.MiddleButton) {
                root.dismissed();
            } else if (!root.compact && root.x > 80) {
                root.swiped();
            } else {
                root.x = 0;
                if (m.button === Qt.LeftButton && root.live && root.entry.actions.some(a => a.id === "default"))
                    Notifs.invoke(root.entry.id, "default");
            }
            pressX = -1;
        }
    }

    Behavior on x {
        enabled: !root.compact
        NumberAnimation {
            duration: Config.animDurationFast
        }
    }

    ColumnLayout {
        id: column

        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            IconImage {
                readonly property string src: Notifs.iconSource(root.entry)

                visible: src !== ""
                implicitSize: 20
                source: src
                asynchronous: true
            }

            StyledText {
                Layout.fillWidth: true
                text: root.entry.appName || "Notification"
                color: Colours.surfaceVariantText
                font.pixelSize: Config.fontSize - 1
                font.weight: Font.DemiBold
            }

            StyledText {
                text: root.timeLabel(root.entry.time)
                color: Colours.surfaceVariantText
                font.pixelSize: Config.fontSize - 2
            }

            IconButton {
                icon: "close"
                size: 24
                iconSize: Config.iconSize - 6
                onClicked: root.dismissed()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ClippingRectangle {
                id: imageBox

                readonly property string src: root.entry.image ?? ""

                visible: src !== ""
                Layout.alignment: Qt.AlignTop
                implicitWidth: root.compact ? 40 : 56
                implicitHeight: implicitWidth
                radius: Config.radius
                color: "transparent"

                Image {
                    anchors.fill: parent
                    source: imageBox.src.startsWith("/") ? "file://" + imageBox.src : imageBox.src
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize: Qt.size(112, 112)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.entry.summary
                    font.weight: Font.DemiBold
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.entry.body
                    textFormat: Text.StyledText
                    color: Colours.surfaceVariantText
                    wrapMode: Text.Wrap
                    maximumLineCount: root.compact ? 3 : 6
                    linkColor: Colours.primary
                    onLinkActivated: link => Quickshell.execDetached(["xdg-open", link])
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            visible: root.live && root.entry.actions.filter(a => a.id !== "default").length > 0
            spacing: 6

            Repeater {
                model: root.entry.actions.filter(a => a.id !== "default")

                Chip {
                    required property var modelData

                    text: modelData.text
                    onClicked: Notifs.invoke(root.entry.id, modelData.id)
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.live && root.entry.hasInlineReply && !root.compact
            spacing: 6

            Rectangle {
                Layout.fillWidth: true
                height: 34
                radius: Config.radius
                color: Colours.surfaceContainerHighest

                TextInput {
                    id: replyField

                    anchors.fill: parent
                    anchors.margins: 8
                    verticalAlignment: TextInput.AlignVCenter
                    color: Colours.surfaceText
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize
                    onAccepted: {
                        if (text)
                            Notifs.reply(root.entry.id, text);
                    }

                    StyledText {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        visible: !replyField.text
                        text: root.entry.replyPlaceholder || "Reply"
                        color: Colours.outline
                    }
                }
            }

            IconButton {
                icon: "send"
                checked: replyField.text !== ""
                onClicked: {
                    if (replyField.text)
                        Notifs.reply(root.entry.id, replyField.text);
                }
            }
        }
    }
}
