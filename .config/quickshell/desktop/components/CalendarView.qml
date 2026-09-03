import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"

// Month grid with event dots: quiet numbers, today as a filled disc, the
// selected day ringed. The parent sets the width; cells scale to it.
ColumnLayout {
    id: root

    readonly property date today: Calendar.today
    property int year: today.getFullYear()
    property int month: today.getMonth()
    property date selected: today
    property bool showHeader: true
    property bool centeredHeader: false   // "<  Month yyyy  >" with the arrows at the ends
    readonly property bool atToday: month === today.getMonth() && year === today.getFullYear()
    readonly property int firstDow: Qt.locale().firstDayOfWeek % 7   // 0 = Sunday
    readonly property int cell: Math.max(24, Math.floor(width / 7))
    property int rowHeight: 0   // 0 = from the cell width; the dashboard fills its tile
    readonly property int cellH: rowHeight > 0 ? rowHeight : Math.round(cell * 0.8)
    readonly property int disc: 28
    readonly property var cells: {
        const first = new Date(year, month, 1);
        const offset = (first.getDay() - firstDow + 7) % 7;
        const start = new Date(year, month, 1 - offset);
        const out = [];
        for (let i = 0; i < 42; i++)
            out.push(new Date(start.getFullYear(), start.getMonth(), start.getDate() + i));
        return out;
    }

    signal daySelected(date d)

    spacing: 6

    function shift(delta: int): void {
        let m = month + delta;
        let y = year;
        while (m < 0) {
            m += 12;
            y--;
        }
        while (m > 11) {
            m -= 12;
            y++;
        }
        month = m;
        year = y;
    }

    function goToday(): void {
        month = today.getMonth();
        year = today.getFullYear();
        selected = today;
    }

    function sameDay(a: date, b: date): bool {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
    }

    RowLayout {
        visible: root.showHeader && root.centeredHeader
        Layout.fillWidth: true
        spacing: 0

        IconButton {
            icon: "chevron_left"
            size: 28
            onClicked: root.shift(-1)
        }

        Clickable {
            Layout.fillWidth: true
            implicitHeight: 28
            radius: Config.radius
            onClicked: root.goToday()   // the title doubles as the "today" jump

            StyledText {
                anchors.centerIn: parent
                text: Qt.formatDate(new Date(root.year, root.month, 1), "MMMM yyyy")
                color: root.atToday ? Colours.surfaceText : Theme.accent
                font.pixelSize: Config.fontSize + 1
                font.weight: Font.Medium
            }
        }

        IconButton {
            icon: "chevron_right"
            size: 28
            onClicked: root.shift(1)
        }
    }

    RowLayout {
        visible: root.showHeader && !root.centeredHeader
        Layout.fillWidth: true

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: Qt.formatDate(new Date(root.year, root.month, 1), "MMMM yyyy")
                font.pixelSize: Config.fontSize + 3
                font.weight: Font.DemiBold
            }

            StyledText {
                text: Qt.formatDate(root.today, "dddd, d MMMM")
                color: Colours.surfaceVariantText
                font.pixelSize: Config.fontSize - 1
            }
        }

        IconButton {
            icon: "chevron_left"
            onClicked: root.shift(-1)
        }

        IconButton {
            icon: "today"
            disabled: root.atToday   // keep the slot so the arrows never move
            opacity: root.atToday ? 0.35 : 1
            onClicked: root.goToday()
        }

        IconButton {
            icon: "chevron_right"
            onClicked: root.shift(1)
        }
    }

    Grid {
        columns: 7
        columnSpacing: 0
        rowSpacing: 0

        Repeater {
            model: 7

            StyledText {
                required property int index

                width: root.cell
                height: 20
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: Qt.locale().dayName((root.firstDow + index) % 7, Locale.ShortFormat)
                color: Colours.alpha(Colours.surfaceText, 0.45)
                font.pixelSize: Config.fontSize - 3
                font.weight: Font.Medium
                font.letterSpacing: 1
                font.capitalization: Font.AllUppercase
            }
        }

        Repeater {
            model: root.cells

            Item {
                id: day

                required property var modelData
                readonly property bool inMonth: modelData.getMonth() === root.month
                readonly property bool isToday: root.sameDay(modelData, root.today)
                readonly property bool isSelected: root.sameDay(modelData, root.selected)
                readonly property var evs: Calendar.eventMap[Calendar.dayKey(modelData)] ?? []

                width: root.cell
                height: root.cellH

                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    Rectangle {
                        width: root.disc
                        height: root.disc
                        radius: root.disc / 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: day.isToday && !Theme.outlined ? Colours.inverseSurface : hover.hovered ? Colours.alpha(Colours.surfaceText, 0.08) : "transparent"
                        border.width: (day.isToday && Theme.outlined) || (day.isSelected && !day.isToday) ? 1 : 0
                        border.color: Theme.accent

                        StyledText {
                            anchors.centerIn: parent
                            text: day.modelData.getDate()
                            color: day.isToday ? (Theme.outlined ? Theme.accent : Colours.inverseSurfaceText) : day.inMonth ? Colours.surfaceText : Colours.alpha(Colours.surfaceText, 0.3)
                            font.pixelSize: Config.fontSize
                            font.weight: day.isToday ? Font.DemiBold : Font.Normal
                        }
                    }

                    Row {
                        visible: day.evs.length > 0
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 2
                        opacity: day.inMonth ? 1 : 0.3

                        Repeater {
                            model: Math.min(3, day.evs.length)

                            Rectangle {
                                required property int index

                                width: 3
                                height: 3
                                radius: 1.5
                                color: day.evs[index].colour || Theme.accent
                            }
                        }
                    }
                }

                HoverHandler {
                    id: hover
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.selected = day.modelData;
                        root.daySelected(day.modelData);
                    }
                }
            }
        }
    }
}
