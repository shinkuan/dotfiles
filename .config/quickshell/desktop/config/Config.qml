pragma Singleton

import Quickshell

Singleton {
    readonly property int borderThickness: 10
    readonly property int borderRounding: 25

    readonly property int barWidth: 44
    readonly property int barPinThreshold: 20

    readonly property real animSpeed: 0.8
    readonly property int animDuration: 300 * animSpeed

    readonly property string fontFamily: "Rubik"
    readonly property string fontFamilyMono: "CaskaydiaCove Nerd Font"
    readonly property string iconFont: "Material Symbols Rounded"
    readonly property int fontSize: 13
    readonly property int iconSize: 21
}
