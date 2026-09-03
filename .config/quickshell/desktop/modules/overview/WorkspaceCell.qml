import QtQuick
import "../../config"
import "../../services"
import "../../components"

// One grid cell: a flat miniature of the monitor. Click to go there; while a
// window is dragged it is a drop target. The windows themselves are drawn
// over the whole grid by the overview.
Rectangle {
    id: root

    required property int cx
    required property int cy
    required property var overview   // OverviewWindow
    readonly property bool current: overview.currentCell && overview.currentCell.activity === Overview.activity && overview.currentCell.x === cx && overview.currentCell.y === cy
    readonly property bool selected: Overview.selX === cx && Overview.selY === cy
    readonly property bool dropTarget: overview.dropCell ? (overview.dropCell.x === cx && overview.dropCell.y === cy) : false

    width: overview.cellW
    height: overview.cellH
    radius: Theme.capsule ? 18 : Theme.outlined ? 0 : Theme.radiusItem
    color: dropTarget ? Colours.mix(Colours.surfaceContainerHigh, Theme.accent, 0.28) : current ? Colours.mix(Colours.surfaceContainerLow, Theme.accent, 0.14) : hover.hovered ? Colours.surfaceContainerHigh : Colours.surfaceContainerLow
    border.width: current || selected || dropTarget ? (Theme.outlined ? 1 : 2) : 1
    border.color: dropTarget || current ? Theme.accent : selected ? Colours.secondary : Theme.ledger ? Colours.outlineVariant : Colours.alpha(Colours.outlineVariant, 0.6)

    Behavior on color {
        ColorAnimation {
            duration: Config.animDurationFast
        }
    }

    HoverHandler {
        id: hover

        onHoveredChanged: {
            if (hovered) {
                Overview.selX = root.cx;
                Overview.selY = root.cy;
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (root.overview.dragWin)
                return;
            KGrid.switchTo(Overview.activity, root.cx, root.cy);
            Overview.hide();
        }
    }

    DropArea {
        anchors.fill: parent
        onEntered: root.overview.dropCell = { x: root.cx, y: root.cy }
        onExited: {
            if (root.dropTarget)
                root.overview.dropCell = null;
        }
    }

    StyledText {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 6
        text: `${root.cx},${root.cy}`
        color: root.current ? Theme.accent : Colours.alpha(Colours.surfaceText, 0.75)
        font.pixelSize: Config.fontSize - 2
        font.family: Config.fontFamilyMono
    }
}
