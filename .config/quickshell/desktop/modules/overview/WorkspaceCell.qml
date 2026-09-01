import QtQuick
import "../../config"
import "../../services"
import "../../components"

// One grid cell: a scaled miniature of the monitor holding its windows.
Rectangle {
    id: root

    required property int cx
    required property int cy
    required property var overview   // OverviewWindow
    required property list<var> windows
    readonly property bool current: overview.currentCell && overview.currentCell.activity === Overview.activity && overview.currentCell.x === cx && overview.currentCell.y === cy
    readonly property bool selected: Overview.selX === cx && Overview.selY === cy

    width: overview.cellW
    height: overview.cellH
    radius: Config.radius
    color: current ? Colours.alpha(Colours.primary, 0.14) : hover.hovered ? Colours.alpha(Colours.surfaceContainerHighest, 0.9) : Colours.alpha(Colours.surfaceContainer, 0.75)
    border.width: current || selected ? 2 : 1
    border.color: current ? Colours.primary : selected ? Colours.secondary : Colours.alpha(Colours.outlineVariant, 0.6)

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
            KGrid.switchTo(Overview.activity, root.cx, root.cy);
            Overview.hide();
        }
    }

    StyledText {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 6
        text: `${root.cx},${root.cy}`
        color: root.current ? Colours.primary : Colours.alpha(Colours.surfaceVariantText, 0.7)
        font.pixelSize: Config.fontSize - 2
        font.family: Config.fontFamilyMono
    }

    Repeater {
        model: root.windows

        WindowPreview {
            required property var modelData

            win: modelData
            overview: root.overview
        }
    }
}
