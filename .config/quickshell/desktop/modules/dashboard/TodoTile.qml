import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../components"

// Tasks from the calendar server: tick to complete, type to add.
DashTile {
    id: root

    readonly property list<var> taskLists: Calendar.lists.filter(l => l.todos)

    // somewhere for keyboard focus to go when the add field is left
    function dropFocus(): void {
        focusSink.forceActiveFocus();
    }

    Item {
        id: focusSink
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StyledText {
                Layout.fillWidth: true
                text: "To do"
                color: Theme.accent
                font.family: Theme.fontLabel
                font.pixelSize: Theme.labelSize
                font.weight: Font.DemiBold
                font.letterSpacing: 1
                font.capitalization: Font.AllUppercase
            }

            MaterialIcon {
                visible: Calendar.error !== ""
                text: "sync_problem"
                color: Colours.error
                font.pixelSize: Config.iconSize - 4

                StyledText {
                    visible: false
                    text: Calendar.error
                }
            }

            Row {
                spacing: 4

                Repeater {
                    model: root.taskLists

                    Rectangle {
                        required property var modelData

                        width: 8
                        height: 8
                        radius: 4
                        color: modelData.colour || Theme.accent
                    }
                }
            }

            Rectangle {
                visible: Calendar.openTodos > 0
                implicitWidth: Math.max(20, count.implicitWidth + 12)
                implicitHeight: 20
                radius: 10
                color: Theme.accent

                StyledText {
                    id: count

                    anchors.centerIn: parent
                    text: Calendar.openTodos
                    color: Theme.accentText
                    font.pixelSize: Config.fontSize - 2
                    font.weight: Font.Bold
                }
            }
        }

        StyledText {
            visible: Calendar.todos.length === 0
            Layout.fillWidth: true
            Layout.topMargin: 6
            text: !Calendar.server ? "Set calendar.url to sync tasks" : Calendar.error !== "" ? Calendar.error : Calendar.loaded ? "Nothing to do" : "Loading…"
            color: Colours.surfaceVariantText
            wrapMode: Text.Wrap
        }

        ListView {
            id: list

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            model: Calendar.todos
            boundsBehavior: Flickable.StopAtBounds

            delegate: TodoRow {}

            // a cut row reads as a bug; fade the overflow instead
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 24
                visible: list.contentHeight > list.height && list.contentY + list.height < list.contentHeight - 1
                gradient: Gradient {
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 1; color: Colours.surfaceContainer }
                }
            }
        }

        // add row: a plus and an inline field
        Item {
            visible: Calendar.server && root.taskLists.length > 0
            Layout.fillWidth: true
            implicitHeight: 30

            MaterialIcon {
                id: plus

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "add"
                color: input.activeFocus ? Theme.accent : Colours.outline
                font.pixelSize: Config.iconSize - 3
            }

            TextInput {
                id: input

                anchors.left: plus.right
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                color: Colours.surfaceText
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
                selectionColor: Theme.accent
                selectedTextColor: Theme.accentText
                clip: true
                onAccepted: {
                    Calendar.addTodo(text, "");
                    text = "";
                }
                // Esc cancels the field before the shell's Esc closes the dashboard
                Keys.onShortcutOverride: event => event.accepted = event.key === Qt.Key_Escape
                Keys.onEscapePressed: cancel()
                onVisibleChanged: {
                    if (!visible)
                        cancel();
                }

                function cancel(): void {
                    text = "";
                    root.dropFocus();
                }

                StyledText {
                    anchors.fill: parent
                    visible: input.text === "" && !input.activeFocus
                    text: "Add a task"
                    color: Colours.outline
                }
            }

            MouseArea {
                anchors.fill: parent
                visible: !input.activeFocus
                cursorShape: Qt.IBeamCursor
                onClicked: input.forceActiveFocus()
            }
        }
    }

    component TodoRow: Item {
        id: row

        required property var modelData
        readonly property real offset: Calendar.dueOffset(modelData)
        readonly property color tint: modelData.colour || Theme.accent

        width: ListView.view.width
        height: 30
        opacity: modelData.pending ? 0.6 : 1

        Clickable {
            id: box

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: 26
            implicitHeight: 26
            radius: 13
            onClicked: Calendar.toggleTodo(row.modelData.id)

            Rectangle {
                anchors.centerIn: parent
                width: 18
                height: 18
                radius: 9
                color: row.modelData.done ? row.tint : "transparent"
                border.width: row.modelData.done ? 0 : 1.5
                border.color: row.tint

                MaterialIcon {
                    anchors.centerIn: parent
                    visible: row.modelData.done
                    text: "check"
                    color: Colours.surfaceContainer
                    font.pixelSize: 14
                    fill: true
                }
            }
        }

        MaterialIcon {
            id: flag

            anchors.left: box.right
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            visible: row.modelData.high && !row.modelData.done
            text: "priority_high"
            color: Colours.tertiary
            font.pixelSize: Config.iconSize - 5
            fill: true
        }

        StyledText {
            anchors.left: flag.visible ? flag.right : box.right
            anchors.leftMargin: 6
            anchors.right: due.visible ? due.left : parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: row.modelData.title
            font.weight: row.modelData.done ? Font.Normal : Font.Medium
            font.strikeout: row.modelData.done
            color: row.modelData.done ? Colours.outline : Colours.surfaceText
            elide: Text.ElideRight
        }

        Rectangle {
            id: due

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: row.modelData.due !== ""
            implicitWidth: dueText.implicitWidth + 14
            implicitHeight: 22
            radius: 8
            color: Colours.surfaceContainerHigh

            StyledText {
                id: dueText

                anchors.centerIn: parent
                text: root.dueLabel(row.modelData, row.offset)
                font.family: Theme.fontMono
                font.pixelSize: Config.fontSize - 3
                font.weight: Font.Medium
                color: row.modelData.done ? Colours.outline : row.offset < 0 ? Colours.error : row.offset === 0 ? Theme.accent : Colours.surfaceVariantText
            }
        }
    }

    function dueLabel(t: var, offset: real): string {
        if (!t.d)
            return "";
        if (offset === 0)
            return "Today";
        if (offset === 1)
            return "Tomorrow";
        if (offset > 1 && offset < 7)
            return Qt.formatDate(t.d, "ddd");
        return Qt.formatDate(t.d, "d MMM");
    }
}
