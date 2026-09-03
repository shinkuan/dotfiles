import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../../config"
import "../../services"
import "../../components"

// Clock, date, the latest notifications and the do-not-disturb switch.
DashTile {
    id: root

    readonly property int shown: 4

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        StyledText {
            text: Qt.formatDateTime(clock.date, "HH:mm")
            font.pixelSize: 52
            font.weight: Font.DemiBold
            font.letterSpacing: -1.5
            lineHeight: 0.9
            lineHeightMode: Text.ProportionalHeight
        }

        StyledText {
            Layout.topMargin: 8
            Layout.fillWidth: true
            text: Qt.formatDate(clock.date, "dddd, d MMMM")
            color: Colours.surfaceVariantText
            font.pixelSize: Config.fontSize + 1
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.topMargin: 18
            Layout.fillWidth: true
            spacing: 8

            StyledText {
                Layout.fillWidth: true
                text: "Notifications"
                color: Theme.accent
                font.family: Theme.fontLabel
                font.pixelSize: Theme.labelSize
                font.weight: Font.DemiBold
                font.letterSpacing: 1
                font.capitalization: Font.AllUppercase
            }

            IconButton {
                visible: Notifs.list.length > 0
                icon: "clear_all"
                size: 24
                onClicked: Notifs.clearAll()
            }

            Rectangle {
                visible: Notifs.list.length > 0
                implicitWidth: Math.max(20, count.implicitWidth + 12)
                implicitHeight: 20
                radius: 10
                color: Theme.accent

                StyledText {
                    id: count

                    anchors.centerIn: parent
                    text: Notifs.list.length
                    color: Theme.accentText
                    font.pixelSize: Config.fontSize - 2
                    font.weight: Font.Bold
                }
            }
        }

        StyledText {
            visible: Notifs.list.length === 0
            Layout.topMargin: 10
            text: "No notifications"
            color: Colours.surfaceVariantText
        }

        ListView {
            Layout.topMargin: 10
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 8
            model: Notifs.list.slice(0, root.shown)
            boundsBehavior: Flickable.StopAtBounds

            delegate: NotifRow {}
        }

        StyledText {
            visible: Notifs.list.length > root.shown
            Layout.alignment: Qt.AlignRight
            text: `+${Notifs.list.length - root.shown} more`
            color: Colours.outline
            font.pixelSize: Config.fontSize - 2
        }

        Clickable {
            Layout.topMargin: 10
            Layout.fillWidth: true
            implicitHeight: 38
            radius: 14
            baseColor: Colours.surfaceContainerHigh
            onClicked: ShellState.toggle("dnd")

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 8
                spacing: 8

                MaterialIcon {
                    text: ShellState.dnd ? "do_not_disturb_on" : "do_not_disturb_off"
                    color: ShellState.dnd ? Theme.accent : Colours.surfaceVariantText
                    font.pixelSize: Config.iconSize - 2
                }

                StyledText {
                    Layout.fillWidth: true
                    text: "Do not disturb"
                    font.weight: Font.Medium
                }

                Toggle {
                    checked: ShellState.dnd
                    onToggled: ShellState.toggle("dnd")
                }
            }
        }
    }

    // one notification: app icon, summary, body, when
    component NotifRow: Item {
        id: row

        required property var modelData
        readonly property string icon: Notifs.iconSource(modelData)

        width: ListView.view.width
        height: 40

        Rectangle {
            id: bubble

            width: 30
            height: 30
            radius: 15
            anchors.verticalCenter: parent.verticalCenter
            color: Colours.surfaceContainerHigh

            IconImage {
                anchors.centerIn: parent
                implicitSize: 18
                visible: row.icon !== ""
                source: row.icon
            }

            MaterialIcon {
                anchors.centerIn: parent
                visible: row.icon === ""
                text: "notifications"
                color: Colours.surfaceVariantText
                font.pixelSize: Config.iconSize - 4
            }
        }

        Column {
            anchors.left: bubble.right
            anchors.leftMargin: 10
            anchors.right: when.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            StyledText {
                width: parent.width
                text: row.modelData.summary || row.modelData.appName
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            StyledText {
                width: parent.width
                visible: text !== ""
                text: (row.modelData.body || row.modelData.appName || "").replace(/\s+/g, " ")
                color: Colours.surfaceVariantText
                font.pixelSize: Config.fontSize - 1
                elide: Text.ElideRight
            }
        }

        StyledText {
            id: when

            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 3
            text: root.timeLabel(row.modelData.time)
            color: Colours.outline
            font.family: Theme.fontMono
            font.pixelSize: Config.fontSize - 3
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            onClicked: mouse => {
                if (mouse.button === Qt.MiddleButton)
                    Notifs.dismiss(row.modelData.key);
                else if (row.modelData.notif && row.modelData.actions.some(a => a.id === "default"))
                    Notifs.invoke(row.modelData.key, "default");
            }
        }
    }

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
}
