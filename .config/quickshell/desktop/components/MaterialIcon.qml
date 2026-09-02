import QtQuick
import "../config"
import "../services"

Text {
    property bool fill: false
    property int weight: Theme.iconWeight

    color: Colours.surfaceText
    font.family: Config.iconFont
    font.pixelSize: Config.iconSize
    font.variableAxes: ({ "FILL": fill ? 1 : 0, "wght": weight })
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
}
