import QtQuick
import QtQuick.Effects
import "../config"
import "../services"

// Themed panel: material, radius, hairline / rim light / corner ticks and
// shadow all come from Theme so every popup reads as the same object.
Item {
    id: root

    property color color: Theme.panel
    property int radius: Theme.radius
    property bool shadow: true
    property color borderColor: Theme.borderColor
    default property alias content: inner.data

    RectangularShadow {
        anchors.fill: inner
        visible: root.shadow && Theme.shadow > 0
        radius: root.radius
        blur: Theme.shadow
        spread: 0
        offset: Qt.vector2d(0, Theme.shadow / 4)
        color: Colours.alpha(Colours.scrim, Theme.shadowOpacity)
    }

    Rectangle {
        id: inner

        anchors.fill: parent
        radius: root.radius
        color: root.color
        border.width: Theme.borderWidth
        border.color: root.borderColor
        clip: true
    }

    // Rim: a lit top edge
    Rectangle {
        visible: Theme.rimLight
        x: parent.width * 0.12
        y: 0
        width: parent.width * 0.76
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 0.3; color: Colours.alpha(Theme.accent, 0.55) }
            GradientStop { position: 0.7; color: Colours.alpha(Theme.accent, 0.55) }
            GradientStop { position: 1; color: "transparent" }
        }
    }

    // Signal: HUD corner brackets
    Repeater {
        model: Theme.cornerTicks ? 2 : 0

        Item {
            required property int index

            x: index === 0 ? -1 : parent.width - 9
            y: index === 0 ? -1 : parent.height - 9
            width: 10
            height: 10

            Rectangle {
                x: 0
                y: parent.parent.index === 0 ? 0 : 9
                width: 10
                height: 1
                color: Theme.accent
            }

            Rectangle {
                x: parent.parent.index === 0 ? 0 : 9
                y: 0
                width: 1
                height: 10
                color: Theme.accent
            }
        }
    }
}
