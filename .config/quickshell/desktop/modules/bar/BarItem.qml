import QtQuick
import "../../config"
import "../../services"

// A bar entry. `popout` names the popout revealed on hover (empty = none).
// Content is laid out in a centred Column.
Rectangle {
    id: root

    property string popout: ""
    property bool shown: true   // entry wants to be in the bar (Item.visible is effective, not own)
    property int spacing: 2
    default property alias content: grid.data
    readonly property alias hovered: hover.hovered
    readonly property Item bar: {
        let p = parent;
        while (p && p.activePopout === undefined)
            p = p.parent;
        return p;
    }
    readonly property bool active: popout !== "" && bar !== null && bar.activePopout === popout
    readonly property bool horizontal: bar?.horizontal ?? false
    // solid directions invert the entry's foreground while it is active
    readonly property bool filled: active && Theme.barItemFilled
    readonly property color fg: filled ? Theme.accentText : Colours.surfaceText
    readonly property color fgDim: filled ? Colours.alpha(Theme.accentText, 0.6) : Colours.outline
    readonly property color fgAccent: filled ? Theme.accentText : Theme.accent

    signal clicked(var mouse)

    implicitWidth: horizontal ? Math.max(Theme.barWidth - 8, grid.implicitWidth + 14) : Theme.barWidth - 8
    implicitHeight: horizontal ? Theme.barWidth - 8 : grid.implicitHeight + 10
    radius: Theme.barItemRadius
    color: active ? (Theme.barItemFilled ? Theme.accent : Theme.barItemOutlined ? "transparent" : Colours.alpha(Theme.accent, 0.18)) : hover.hovered ? Colours.alpha(Colours.surfaceText, 0.08) : "transparent"
    border.width: active && Theme.barItemOutlined ? 1 : 0
    border.color: Theme.accent

    // Rim / Ledger: a 2px indicator on the screen edge
    Rectangle {
        visible: root.active && Theme.activeBar
        x: root.horizontal ? 6 : Theme.barRight ? (Theme.rim ? root.width + 2 : root.width + (Theme.barWidth - root.width) / 2 - 2) : (Theme.rim ? -4 : -(Theme.barWidth - root.width) / 2)
        y: root.horizontal ? (Theme.rim ? -4 : -(Theme.barWidth - root.height) / 2) : 6
        width: root.horizontal ? parent.width - 12 : 2
        height: root.horizontal ? 2 : parent.height - 12
        radius: 1
        color: Theme.accent
    }

    scale: hover.hovered ? Theme.hoverScale : 1

    Behavior on scale {
        NumberAnimation {
            duration: Config.animDurationFast
            easing.type: Easing.OutBack
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: Config.animDurationFast
        }
    }

    // content flows with the bar; children must not anchor themselves
    Grid {
        id: grid

        anchors.centerIn: parent
        flow: root.horizontal ? Grid.LeftToRight : Grid.TopToBottom
        columns: root.horizontal ? 99 : 1
        rowSpacing: root.spacing
        columnSpacing: root.spacing + 4
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter
    }

    HoverHandler {
        id: hover
    }

    MouseArea {
        property real pressX: -1
        property real pressY: -1

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onPressed: m => {
            pressX = m.x;
            pressY = m.y;
        }
        onReleased: {
            pressX = -1;
            pressY = -1;
        }
        onPositionChanged: m => {
            if (pressX >= 0 && root.bar)
                root.bar.dragged(root.horizontal ? m.y - pressY : m.x - pressX);
        }
        onClicked: m => {
            root.clicked(m);
            // left click keeps the popout open until Esc / a click elsewhere
            if (m.button === Qt.LeftButton && root.popout !== "" && root.bar)
                root.bar.itemClicked(root.popout, root.horizontal ? root.mapToItem(root.bar, root.width / 2, 0).x : root.mapToItem(root.bar, 0, root.height / 2).y);
        }
    }
}
