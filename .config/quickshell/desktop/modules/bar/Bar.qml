import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../config"
import "../../services"

Item {
    id: root

    required property HyprlandMonitor monitor
    property bool revealed: false
    property string activePopout: ""
    readonly property real exposedWidth: width + x

    signal dragged(real dx)
    signal itemClicked(string popout, real y)

    width: Theme.barWidth
    x: revealed ? Theme.barMargin : -width

    Behavior on x {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutCubic
        }
    }

    function collect(item: Item, out): void {
        for (const c of item.children) {
            if (!c.visible)
                continue;
            if (c.popout !== undefined) {
                if (c.popout !== "")
                    out.push(c);
            } else {
                collect(c, out);
            }
        }
    }

    // popout entry under bar-local y, or null
    function popoutAt(y: real): var {
        const items = [];
        collect(layout, items);
        for (const it of items) {
            const p = it.mapToItem(root, 0, 0);
            if (y >= p.y && y < p.y + it.height)
                return { id: it.popout, y: p.y + it.height / 2 };
        }
        return null;
    }

    function anchorFor(id: string): real {
        const items = [];
        collect(layout, items);
        const it = items.find(i => i.popout === id);
        if (!it)
            return height / 2;
        const p = it.mapToItem(root, 0, 0);
        return p.y + it.height / 2;
    }

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: Theme.barMargin
        anchors.bottomMargin: Theme.barMargin
        color: Theme.barColor
        radius: Theme.capsule ? Theme.barRadius : 0
        topRightRadius: Theme.barRadius
        bottomRightRadius: Theme.barRadius

        // Ledger / Signal / Rim: a hairline on the exposed edge
        Rectangle {
            visible: Theme.barEdgeLine
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: Theme.rim ? Theme.barRadius : 0
            anchors.bottomMargin: Theme.rim ? Theme.barRadius : 0
            width: 1
            color: Theme.signal ? Colours.alpha(Theme.accent, 0.25) : Colours.alpha(Colours.outlineVariant, Theme.rim ? 0.5 : 1)
        }
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.topMargin: 10 + Theme.barMargin
        anchors.bottomMargin: 10 + Theme.barMargin
        spacing: 6

        KGridIndicator {
            Layout.alignment: Qt.AlignHCenter
            monitor: root.monitor
        }

        ActiveWindow {
            Layout.alignment: Qt.AlignHCenter
        }

        Item {
            Layout.fillHeight: true
        }

        MediaModule {
            Layout.alignment: Qt.AlignHCenter
        }

        ResourcesModule {
            Layout.alignment: Qt.AlignHCenter
            visible: Config.bar.showResources
        }

        Tray {
            Layout.alignment: Qt.AlignHCenter
        }

        StatusIcons {
            Layout.alignment: Qt.AlignHCenter
        }

        NotifIcon {
            Layout.alignment: Qt.AlignHCenter
        }

        Clock {
            Layout.alignment: Qt.AlignHCenter
        }

        PowerButton {
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
