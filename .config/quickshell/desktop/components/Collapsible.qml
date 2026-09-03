import QtQuick
import QtQuick.Layouts
import "../config"

// Height-animated container: `open` reveals the content, closed takes no space.
Item {
    id: root

    property bool open: false
    default property alias content: inner.data

    Layout.fillWidth: true
    clip: true
    visible: implicitHeight > 0.5
    implicitHeight: open ? inner.implicitHeight : 0

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Theme.spatialDuration
            easing.type: Theme.spatialType
            easing.bezierCurve: Theme.spatialCurve
        }
    }

    ColumnLayout {
        id: inner

        width: root.width
        spacing: 2
    }
}
