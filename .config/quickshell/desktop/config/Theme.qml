pragma Singleton

import QtQuick
import Quickshell
import "../services"

// Visual direction tokens. `Config.appearance.style` picks a preset; every
// component reads these instead of hard-coding shape, material or type.
Singleton {
    id: root

    readonly property string style: Config.appearance.style
    readonly property bool rim: style === "rim"
    readonly property bool ledger: style === "ledger"
    readonly property bool capsule: style === "capsule"
    readonly property bool signal: style === "signal"
    readonly property bool poster: style === "poster"

    // type
    readonly property string font: capsule ? "Rubik" : signal ? "IBM Plex Mono" : "IBM Plex Sans"
    readonly property string fontMono: "IBM Plex Mono"
    readonly property string fontLabel: (rim || poster) ? "IBM Plex Sans Condensed" : (ledger || signal) ? "IBM Plex Mono" : capsule ? "Rubik" : "IBM Plex Sans"
    readonly property int labelSize: signal ? 10 : capsule ? 12 : poster ? 14 : 11
    readonly property int labelWeight: poster ? Font.Bold : rim ? Font.DemiBold : Font.Medium
    readonly property bool labelUpper: !capsule
    readonly property real labelSpacing: signal ? 2.4 : rim ? 1.5 : ledger ? 1 : capsule ? 0 : poster ? 0.5 : 1
    readonly property color labelColor: signal ? Colours.tertiary : ledger ? Colours.surfaceVariantText : capsule ? Colours.outline : poster ? Colours.surfaceText : Colours.primary
    readonly property bool labelRuled: ledger || poster  // rule under section labels
    readonly property int labelRuleWidth: poster ? 3 : 1
    readonly property color labelRuleColor: poster ? accent : Colours.outlineVariant
    readonly property bool labelMarker: signal         // small square before the label

    // accent: what "current" looks like
    readonly property color accent: signal ? Colours.tertiary : Colours.primary
    readonly property color accentText: signal ? Colours.tertiaryText : Colours.primaryText
    readonly property color activeFill: ledger ? "transparent" : capsule ? Colours.secondaryContainer : poster ? Colours.primaryContainer : Colours.alpha(accent, rim ? 0.11 : signal ? 0.12 : 0.16)
    readonly property color activeText: capsule ? Colours.surfaceText : poster ? Colours.primaryContainerText : accent
    readonly property color activeIcon: poster ? Colours.primaryContainerText : accent
    readonly property bool activeBar: rim || ledger    // 2px indicator on the left edge
    readonly property bool activeUnderline: signal
    readonly property bool activePill: capsule

    // surfaces
    readonly property color panel: poster ? Colours.surfaceContainerLow : rim ? Colours.alpha(Colours.surfaceContainerLowest, 0.86) : ledger ? Colours.mix(Colours.surfaceContainerLow, Colours.surfaceContainerLowest, 0.4) : capsule ? Colours.alpha(Colours.surfaceContainerLow, 0.96) : signal ? Colours.alpha(Colours.surfaceContainerLowest, 0.72) : Colours.surfaceContainer
    readonly property color panelRaised: poster ? Colours.surfaceContainerLowest : ledger ? Colours.surfaceContainer : capsule ? Colours.surfaceContainerHigh : (rim || signal) ? Colours.alpha(Colours.surfaceText, 0.05) : Colours.surfaceContainerHigh
    readonly property color field: poster ? Colours.surfaceContainerLowest : capsule ? Colours.surfaceContainerHighest : (rim || signal) ? Colours.alpha(Colours.surfaceText, 0.05) : Colours.surfaceContainerHighest
    readonly property int radius: rim ? 18 : ledger ? 4 : capsule ? 28 : signal ? 2 : poster ? 6 : 20
    readonly property int radiusItem: rim ? 10 : ledger ? 0 : capsule ? 14 : signal ? 2 : poster ? 4 : 12
    readonly property int radiusChip: (ledger || signal) ? 2 : poster ? 4 : 999
    readonly property int radiusTile: rim ? 12 : ledger ? 2 : capsule ? 20 : signal ? 2 : poster ? 6 : 14
    readonly property bool solid: poster                // chips / tiles / bar entries are solid blocks
    readonly property int borderWidth: (ledger || signal || rim) ? 1 : 0
    readonly property color borderColor: signal ? Colours.alpha(Colours.tertiary, 0.18) : rim ? Colours.alpha(Colours.outlineVariant, 0.45) : ledger ? Colours.outlineVariant : Colours.alpha(Colours.outlineVariant, 0.5)
    readonly property bool rimLight: rim                // lit top edge
    readonly property bool cornerTicks: signal          // HUD corner brackets
    readonly property bool outlined: ledger || signal   // chips / tiles drawn as outlines, not fills
    readonly property bool ruledRows: ledger            // dashed dividers between rows
    readonly property bool segmented: signal            // tick-mark sliders and meters
    readonly property int shadow: ledger ? 24 : capsule ? 40 : signal ? 0 : poster ? 30 : 28
    readonly property real shadowOpacity: capsule ? 0.45 : 0.5
    readonly property int padding: capsule ? 18 : 14
    readonly property real popScale: capsule ? 0.85 : poster ? 1 : signal ? 0.98 : 0.92

    // bar
    readonly property bool barTop: Config.bar.position === "top"
    readonly property bool barRight: Config.bar.position === "right"
    readonly property int barWidth: ledger ? 40 : (capsule || poster) ? 48 : 44
    readonly property int barMargin: capsule ? 10 : 0           // detached from the screen edge
    readonly property int barSpan: barWidth + barMargin * 2
    readonly property int barRadius: capsule ? 24 : rim ? 22 : (ledger || signal || poster) ? 0 : 25
    readonly property color barColor: poster ? Colours.surfaceContainerLowest : capsule ? Colours.alpha(Colours.surfaceContainerLow, 0.96) : rim ? Colours.alpha(Colours.surfaceContainerLowest, 0.9) : ledger ? Colours.surfaceContainerLowest : signal ? Colours.alpha(Colours.surfaceContainerLowest, 0.72) : Colours.alpha(Colours.surface, 0.92)
    readonly property bool barEdgeLine: ledger || signal || rim
    readonly property int barItemRadius: capsule ? 20 : ledger ? 0 : signal ? 2 : poster ? 4 : 10
    readonly property bool barItemFilled: capsule || poster  // active bar entry is a filled block
    readonly property bool barItemOutlined: signal
}
