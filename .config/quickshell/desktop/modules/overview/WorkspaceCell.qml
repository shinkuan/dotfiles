import QtQuick
import Quickshell.Widgets
import "../../config"
import "../../services"
import "../../components"

// One grid cell: a scaled miniature of the monitor (wallpaper included, so
// translucent windows composite the way they do on screen). Clicks and
// drags are handled by the overview's grid-level MouseArea.
ClippingRectangle {
    id: root

    required property int cx
    required property int cy
    required property var overview   // OverviewWindow
    required property list<var> windows
    readonly property bool current: overview.currentCell && overview.currentCell.activity === Overview.activity && overview.currentCell.x === cx && overview.currentCell.y === cy
    readonly property bool selected: Overview.selX === cx && Overview.selY === cy
    readonly property bool dropTarget: overview.dropCell ? (overview.dropCell.x === cx && overview.dropCell.y === cy) : false

    width: overview.cellW
    height: overview.cellH
    radius: Theme.capsule ? 18 : Theme.outlined ? 0 : Theme.radiusItem
    color: Colours.surfaceContainerLow
    border.width: current || selected || dropTarget ? (Theme.outlined ? 1 : 2) : 1
    border.color: dropTarget || current ? Theme.accent : selected ? Colours.secondary : Theme.ledger ? Colours.outlineVariant : Colours.alpha(Colours.outlineVariant, 0.6)

    Image {
        anchors.fill: parent
        source: Wallpaper.path ? "file://" + Wallpaper.path : ""
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: root.width
        sourceSize.height: root.height
        asynchronous: true
        visible: status === Image.Ready
    }

    Rectangle {
        anchors.fill: parent
        color: root.dropTarget ? Colours.alpha(Theme.accent, 0.28) : root.current ? Colours.alpha(Theme.accent, 0.16) : hover.hovered ? Colours.alpha(Colours.surface, 0.3) : Colours.alpha(Colours.surface, 0.5)

        Behavior on color {
            ColorAnimation {
                duration: Config.animDurationFast
            }
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

    StyledText {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 6
        text: `${root.cx},${root.cy}`
        color: root.current ? Theme.accent : Colours.alpha(Colours.surfaceText, 0.75)
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
