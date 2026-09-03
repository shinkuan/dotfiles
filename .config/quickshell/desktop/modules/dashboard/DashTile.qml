import QtQuick
import "../../config"
import "../../services"

// One rounded tile of the dashboard grid.
Rectangle {
    id: root

    property int pad: 16
    default property alias content: inner.data
    readonly property real innerWidth: width - pad * 2
    readonly property real innerHeight: height - pad * 2

    radius: Theme.frame ? 28 : Theme.radius
    color: Colours.surfaceContainer

    Item {
        id: inner

        x: root.pad
        y: root.pad
        width: root.innerWidth
        height: root.innerHeight
    }
}
