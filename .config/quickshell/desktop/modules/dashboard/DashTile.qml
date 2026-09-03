import QtQuick
import "../../config"
import "../../services"

// One tile of the dashboard grid. Corners on the panel's outer edge round
// with the panel (frame style); the inner ones stay tighter.
Rectangle {
    id: root

    property int pad: 16
    property bool outerTL: false
    property bool outerTR: false
    property bool outerBL: false
    property bool outerBR: false
    default property alias content: inner.data
    readonly property real innerWidth: width - pad * 2
    readonly property real innerHeight: height - pad * 2
    readonly property int outerRadius: Theme.frame ? 28 : Theme.radius
    readonly property int innerRadius: Theme.frame ? 16 : Theme.radiusTile

    topLeftRadius: outerTL ? outerRadius : innerRadius
    topRightRadius: outerTR ? outerRadius : innerRadius
    bottomLeftRadius: outerBL ? outerRadius : innerRadius
    bottomRightRadius: outerBR ? outerRadius : innerRadius
    color: Colours.surfaceContainer

    Item {
        id: inner

        x: root.pad
        y: root.pad
        width: root.innerWidth
        height: root.innerHeight
    }
}
