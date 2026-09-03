import QtQuick
import "../config"
import "../services"

// Native glyph rendering: crisp, hinted text like caelestia's, not distance-field soft.
Text {
    renderType: Text.NativeRendering
    color: Colours.surfaceText
    font.family: Config.fontFamily
    font.pixelSize: Config.fontSize
    elide: Text.ElideRight
}
