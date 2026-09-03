import QtQuick
import "../config"
import "../services"

// Compact event rows, optionally grouped under day headers. Set `height`
// (or Layout.preferredHeight) to cap it; implicitHeight is the full list.
Item {
    id: root

    property list<var> events: []
    property bool grouped: true
    property string emptyText: "Nothing scheduled"
    readonly property int rowHeight: 34
    readonly property int headerHeight: 24
    readonly property var rows: {
        const out = [];
        let lastKey = "";
        for (const ev of events) {
            const key = Calendar.dayKey(ev.s);
            if (grouped && key !== lastKey) {
                out.push({ header: root.dayLabel(ev.s), key: key });
                lastKey = key;
            }
            out.push({ ev: ev });
        }
        return out;
    }

    implicitHeight: events.length === 0 ? rowHeight : list.contentHeight
    implicitWidth: 240

    function dayLabel(d: date): string {
        const t = Calendar.today;
        const diff = Math.round((new Date(d.getFullYear(), d.getMonth(), d.getDate()) - new Date(t.getFullYear(), t.getMonth(), t.getDate())) / 86400000);
        if (diff === 0)
            return "Today";
        if (diff === 1)
            return "Tomorrow";
        if (diff === -1)
            return "Yesterday";
        return Qt.formatDate(d, "ddd d MMM");
    }

    function timeLabel(ev: var): string {
        if (ev.allDay)
            return "All day";
        const s = Qt.formatTime(ev.s, "HH:mm");
        const e = Qt.formatTime(ev.e, "HH:mm");
        return s === e ? s : `${s}–${e}`;
    }

    StyledText {
        visible: root.events.length === 0
        anchors.centerIn: parent
        text: root.emptyText
        color: Colours.surfaceVariantText
    }

    ListView {
        id: list

        anchors.fill: parent
        clip: true
        model: root.rows
        boundsBehavior: Flickable.StopAtBounds

        delegate: Item {
            id: row

            required property var modelData
            readonly property bool isHeader: modelData.header !== undefined

            width: list.width
            height: isHeader ? root.headerHeight : root.rowHeight

            StyledText {
                visible: row.isHeader
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 4
                text: (row.modelData.header ?? "").toUpperCase()
                color: row.modelData.header === "Today" ? Theme.accent : Colours.surfaceVariantText
                font.family: Theme.fontLabel
                font.pixelSize: Theme.labelSize
                font.weight: Font.DemiBold
                font.letterSpacing: 1
            }

            Row {
                visible: !row.isHeader
                anchors.fill: parent
                spacing: 10

                Rectangle {
                    width: 3
                    height: 20
                    radius: 1.5
                    anchors.verticalCenter: parent.verticalCenter
                    color: row.isHeader ? "transparent" : ((row.modelData.ev?.colour ?? "") || Theme.accent)
                }

                StyledText {
                    width: 88
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.isHeader ? "" : root.timeLabel(row.modelData.ev)
                    color: Colours.surfaceVariantText
                    font.family: Theme.fontMono
                    font.pixelSize: Config.fontSize - 2
                }

                Column {
                    width: parent.width - 3 - 88 - 20
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0

                    StyledText {
                        width: parent.width
                        text: row.isHeader ? "" : row.modelData.ev.title
                        font.pixelSize: Config.fontSize
                    }

                    StyledText {
                        visible: !row.isHeader && (row.modelData.ev.location ?? "") !== ""
                        width: parent.width
                        text: row.isHeader ? "" : row.modelData.ev.location
                        color: Colours.surfaceVariantText
                        font.pixelSize: Config.fontSize - 3
                    }
                }
            }
        }
    }
}
