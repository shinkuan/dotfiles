import QtQuick
import "../../config"
import "../../services"

// Frame style: the screen border and every panel attached to it are one
// signed-distance shape, so panels grow out of the frame instead of
// floating next to it. Panel slots are rects in this item's coordinates.
ShaderEffect {
    id: root

    property vector2d size: Qt.vector2d(width, height)
    property vector4d frame: Qt.vector4d(0, 0, 0, 0)
    property real rounding: Config.borderRounding
    property real smoothing: 20
    property color color: Colours.surface
    property color shadowColor: Colours.alpha(Colours.scrim, 0.3)
    property vector4d p0: Qt.vector4d(0, 0, 0, 0)
    property vector4d p1: Qt.vector4d(0, 0, 0, 0)
    property vector4d p2: Qt.vector4d(0, 0, 0, 0)
    property vector4d p3: Qt.vector4d(0, 0, 0, 0)
    property vector4d radii: Qt.vector4d(Theme.radius, Theme.radius, Theme.radius, Theme.radius)

    fragmentShader: "frame.frag.qsb"
}
