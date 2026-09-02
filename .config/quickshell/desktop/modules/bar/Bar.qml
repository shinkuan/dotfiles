import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Hyprland
import "../../config"
import "../../services"

Item {
    id: root

    required property HyprlandMonitor monitor
    property bool revealed: false
    property string activePopout: ""
    readonly property bool horizontal: Theme.barTop
    readonly property bool mirrored: Theme.barRight
    // how far the bar currently reaches into the screen, measured from its own edge
    readonly property real exposedWidth: horizontal ? height + y : mirrored ? parent.width - x : width + x

    signal dragged(real dx)
    signal itemClicked(string popout, real y)

    readonly property var registry: ({
        kgrid: kgridComp,
        window: windowComp,
        spacer: spacerComp,
        media: mediaComp,
        resources: resourcesComp,
        tray: trayComp,
        status: statusComp,
        notifications: notifComp,
        clock: clockComp,
        power: powerComp
    })

    Component { id: kgridComp; KGridIndicator { monitor: root.monitor } }
    Component { id: windowComp; ActiveWindow {} }
    Component { id: spacerComp; Item {} }
    Component { id: mediaComp; MediaModule {} }
    Component { id: resourcesComp; ResourcesModule { shown: Config.bar.showResources } }
    Component { id: trayComp; Tray {} }
    Component { id: statusComp; StatusIcons {} }
    Component { id: notifComp; NotifIcon {} }
    Component { id: clockComp; Clock {} }
    Component { id: powerComp; PowerButton {} }

    // explicit geometry: anchors cannot be toggled reliably at runtime
    width: horizontal ? parent.width : Theme.barWidth
    height: horizontal ? Theme.barWidth : parent.height
    x: horizontal ? 0 : mirrored ? (revealed ? parent.width - width - Theme.barMargin : parent.width) : (revealed ? Theme.barMargin : -width)
    y: horizontal ? (revealed ? Theme.barMargin : -height) : 0

    Behavior on x {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on y {
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

    // popout entry under the bar-local coordinate along the bar's axis
    function popoutAt(pos: real): var {
        const items = [];
        collect(layout, items);
        for (const it of items) {
            const p = it.mapToItem(root, 0, 0);
            const start = horizontal ? p.x : p.y;
            const size = horizontal ? it.width : it.height;
            if (pos >= start && pos < start + size)
                return { id: it.popout, y: start + size / 2 };
        }
        return null;
    }

    function anchorFor(id: string): real {
        const items = [];
        collect(layout, items);
        const it = items.find(i => i.popout === id);
        if (!it)
            return (horizontal ? width : height) / 2;
        const p = it.mapToItem(root, 0, 0);
        return horizontal ? p.x + it.width / 2 : p.y + it.height / 2;
    }

    RectangularShadow {
        anchors.fill: barBg
        visible: Theme.shadow > 0 && (Theme.capsule || Theme.rim || Theme.poster)
        radius: Theme.barRadius
        blur: Theme.shadow
        spread: 0
        offset: Qt.vector2d(Theme.capsule ? 0 : (root.mirrored ? -6 : 6), Theme.capsule ? 8 : 0)
        color: Colours.alpha(Colours.scrim, Theme.shadowOpacity)
    }

    Rectangle {
        id: barBg

        anchors.fill: parent
        anchors.topMargin: root.horizontal ? 0 : Theme.barMargin
        anchors.bottomMargin: root.horizontal ? 0 : Theme.barMargin
        anchors.leftMargin: root.horizontal ? Theme.barMargin : 0
        anchors.rightMargin: root.horizontal ? Theme.barMargin : 0
        color: Theme.barColor
        radius: Theme.capsule ? Theme.barRadius : 0
        topLeftRadius: (root.mirrored || Theme.capsule) ? Theme.barRadius : 0
        topRightRadius: (root.horizontal || root.mirrored) ? (Theme.capsule ? Theme.barRadius : 0) : Theme.barRadius
        bottomRightRadius: root.mirrored ? (Theme.capsule ? Theme.barRadius : 0) : Theme.barRadius
        bottomLeftRadius: (root.horizontal || root.mirrored) ? Theme.barRadius : (Theme.capsule ? Theme.barRadius : 0)

        // Signal: brackets on the exposed corners
        Repeater {
            model: Theme.cornerTicks ? 2 : 0

            Item {
                required property int index

                x: parent.width - 10
                y: index === 0 ? 0 : parent.height - 10
                width: 10
                height: 10

                Rectangle {
                    x: 0
                    y: parent.index === 0 ? 0 : 9
                    width: 10
                    height: 1
                    color: Theme.accent
                }

                Rectangle {
                    x: 9
                    y: 0
                    width: 1
                    height: 10
                    color: Theme.accent
                }
            }
        }

        // Ledger / Signal / Rim: a hairline on the exposed edge
        Rectangle {
            visible: Theme.barEdgeLine && !root.horizontal
            anchors.right: root.mirrored ? undefined : parent.right
            anchors.left: root.mirrored ? parent.left : undefined
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: Theme.rim ? Theme.barRadius : 0
            anchors.bottomMargin: Theme.rim ? Theme.barRadius : 0
            width: 1
            color: Theme.signal ? Colours.alpha(Theme.accent, 0.25) : Colours.alpha(Colours.outlineVariant, Theme.rim ? 0.5 : 1)
        }

        Rectangle {
            visible: Theme.barEdgeLine && root.horizontal
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Theme.rim ? Theme.barRadius : 0
            anchors.rightMargin: Theme.rim ? Theme.barRadius : 0
            height: 1
            color: Theme.signal ? Colours.alpha(Theme.accent, 0.25) : Colours.alpha(Colours.outlineVariant, Theme.rim ? 0.5 : 1)
        }
    }

    GridLayout {
        id: layout

        readonly property int align: root.horizontal ? Qt.AlignVCenter : Qt.AlignHCenter

        anchors.fill: parent
        anchors.topMargin: root.horizontal ? 0 : 10 + Theme.barMargin
        anchors.bottomMargin: root.horizontal ? 0 : 10 + Theme.barMargin
        anchors.leftMargin: root.horizontal ? 10 + Theme.barMargin : 0
        anchors.rightMargin: root.horizontal ? 10 + Theme.barMargin : 0
        flow: root.horizontal ? GridLayout.LeftToRight : GridLayout.TopToBottom
        columns: root.horizontal ? -1 : 1
        rows: root.horizontal ? 1 : -1
        columnSpacing: 6
        rowSpacing: 6

        Repeater {
            model: Config.bar.entries

            Loader {
                required property string modelData

                Layout.alignment: layout.align
                Layout.fillHeight: modelData === "spacer" && !root.horizontal
                Layout.fillWidth: modelData === "spacer" && root.horizontal
                visible: modelData === "spacer" || (item?.shown ?? true)
                sourceComponent: root.registry[modelData] ?? null
            }
        }
    }
}
