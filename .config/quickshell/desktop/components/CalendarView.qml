import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"

// Month grid with event dots. The parent sets the width; cells scale to it.
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
    readonly property int gap: 2
    readonly property int cell: Math.max(24, Math.floor((width - 6 * gap) / 7))
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

        IconButton {
            icon: "chevron_left"
            onClicked: root.shift(-1)
        }

        Clickable {
            Layout.fillWidth: true
            implicitHeight: 32
            radius: Config.radius
            onClicked: root.goToday()   // the title doubles as the "today" jump

            StyledText {
                anchors.centerIn: parent
                text: Qt.formatDate(new Date(root.year, root.month, 1), "MMMM yyyy")
                color: root.atToday ? Colours.surfaceText : Theme.accent
                font.pixelSize: Config.fontSize + 3
                font.weight: Font.DemiBold
            }
        }

        IconButton {
            icon: "chevron_right"
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
        columnSpacing: root.gap
        rowSpacing: root.gap

        Repeater {
            model: 7

            StyledText {
                required property int index

                width: root.cell
                horizontalAlignment: Text.AlignHCenter
                text: Qt.locale().dayName((root.firstDow + index) % 7, Locale.ShortFormat)
                color: Colours.surfaceVariantText
                font.pixelSize: Config.fontSize - 2
                font.weight: Font.DemiBold
            }
        }

        Repeater {
            model: root.cells

            Rectangle {
                id: day

                required property var modelData
                readonly property bool inMonth: modelData.getMonth() === root.month
                readonly property bool isToday: root.sameDay(modelData, root.today)
                readonly property bool isSelected: root.sameDay(modelData, root.selected)
                readonly property bool weekend: modelData.getDay() === 0 || modelData.getDay() === 6
                readonly property var evs: Calendar.eventMap[Calendar.dayKey(modelData)] ?? []

                width: root.cell
                height: Math.round(root.cell * 0.9)
                radius: Theme.capsule ? height / 2 : Theme.outlined ? 0 : Theme.radiusItem
                color: isToday && !Theme.outlined ? Theme.accent : hover.hovered ? Colours.alpha(Colours.surfaceText, 0.08) : "transparent"
                border.width: (isToday && Theme.signal) || (isSelected && !isToday) ? 1 : 0
                border.color: isSelected && !isToday ? Colours.alpha(Theme.accent, 0.8) : Theme.accent

                // Ledger: today is underscored, not filled
                Rectangle {
                    visible: day.isToday && Theme.ledger
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 20
                    height: 2
                    color: Theme.accent
                }

                StyledText {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: day.evs.length > 0 ? -3 : 0
                    text: day.modelData.getDate()
                    color: day.isToday ? (Theme.outlined ? Theme.accent : Theme.accentText) : !day.inMonth ? Colours.alpha(Colours.surfaceVariantText, 0.35) : day.weekend ? Colours.tertiary : Colours.surfaceText
                    font.weight: day.isToday ? Font.Bold : Font.Normal
                }

                Row {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 4
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 2
                    opacity: day.inMonth ? 1 : 0.4

                    Repeater {
                        model: Math.min(3, day.evs.length)

                        Rectangle {
                            required property int index

                            width: 4
                            height: 4
                            radius: 2
                            color: day.isToday && !Theme.outlined ? Theme.accentText : (day.evs[index].colour || Theme.accent)
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
