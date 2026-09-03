import QtQuick
import "../../config"
import "../../services"

// Thin arc gauge; `value` 0..1, drawn clockwise from the top.
Item {
    id: root

    property real value: 0
    property int thickness: 6
    property color track: Colours.surfaceContainerHighest
    property color fill: Theme.accent
    property real shown: 0
    default property alias content: centre.data

    implicitWidth: 84
    implicitHeight: 84

    onValueChanged: shown = Math.max(0, Math.min(1, value))
    onShownChanged: canvas.requestPaint()
    onTrackChanged: canvas.requestPaint()
    onFillChanged: canvas.requestPaint()
    Component.onCompleted: shown = Math.max(0, Math.min(1, value))

    Behavior on shown {
        NumberAnimation {
            duration: Theme.spatialDuration
            easing.type: Theme.spatialType
            easing.bezierCurve: Theme.spatialCurve
        }
    }

    Canvas {
        id: canvas

        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const cx = width / 2, cy = height / 2;
            const r = Math.min(width, height) / 2 - root.thickness / 2;
            ctx.lineWidth = root.thickness;
            ctx.lineCap = "round";
            ctx.strokeStyle = root.track;
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, Math.PI * 2);
            ctx.stroke();
            if (root.shown > 0.002) {
                ctx.strokeStyle = root.fill;
                ctx.beginPath();
                ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * root.shown);
                ctx.stroke();
            }
        }
    }

    Item {
        id: centre

        anchors.fill: parent
    }
}
