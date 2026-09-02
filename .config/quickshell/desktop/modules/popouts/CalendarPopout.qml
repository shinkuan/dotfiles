import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../config"
import "../../services"
import "../../components"

ColumnLayout {
    id: root

    property date today: clock.date
    property int year: today.getFullYear()
    property int month: today.getMonth()
    readonly property int firstDow: Qt.locale().firstDayOfWeek % 7   // 0 = Sunday
    readonly property var cells: {
        const first = new Date(year, month, 1);
        const offset = (first.getDay() - firstDow + 7) % 7;
        const start = new Date(year, month, 1 - offset);
        const out = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i);
            out.push(d);
        }
        return out;
    }

    width: 7 * 38 + 6 * 2
    spacing: 6

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

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

    RowLayout {
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
            visible: root.month !== root.today.getMonth() || root.year !== root.today.getFullYear()
            onClicked: {
                root.month = root.today.getMonth();
                root.year = root.today.getFullYear();
            }
        }

        IconButton {
            icon: "chevron_right"
            onClicked: root.shift(1)
        }
    }

    Grid {
        columns: 7
        columnSpacing: 2
        rowSpacing: 2

        Repeater {
            model: 7

            StyledText {
                required property int index

                width: 38
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
                required property var modelData
                readonly property bool inMonth: modelData.getMonth() === root.month
                readonly property bool isToday: modelData.getFullYear() === root.today.getFullYear() && modelData.getMonth() === root.today.getMonth() && modelData.getDate() === root.today.getDate()
                readonly property bool weekend: modelData.getDay() === 0 || modelData.getDay() === 6

                width: 38
                height: 34
                radius: Theme.capsule ? 17 : Theme.outlined ? 0 : Theme.radiusItem
                color: isToday && !Theme.outlined ? Theme.accent : "transparent"
                border.width: isToday && Theme.signal ? 1 : 0
                border.color: Theme.accent

                // Ledger: today is underscored, not filled
                Rectangle {
                    visible: parent.isToday && Theme.ledger
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 20
                    height: 2
                    color: Theme.accent
                }

                StyledText {
                    anchors.centerIn: parent
                    text: parent.modelData.getDate()
                    color: parent.isToday ? (Theme.outlined ? Theme.accent : Theme.accentText) : !parent.inMonth ? Colours.alpha(Colours.surfaceVariantText, 0.35) : parent.weekend ? Colours.tertiary : Colours.surfaceText
                    font.weight: parent.isToday ? Font.Bold : Font.Normal
                }
            }
        }
    }
}
