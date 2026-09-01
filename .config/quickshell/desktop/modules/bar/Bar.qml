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

    width: Config.barWidth
    x: revealed ? 0 : -width

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
        color: Colours.alpha(Colours.surface, 0.92)
        topRightRadius: Config.borderRounding
        bottomRightRadius: Config.borderRounding
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.topMargin: 10
        anchors.bottomMargin: 10
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
