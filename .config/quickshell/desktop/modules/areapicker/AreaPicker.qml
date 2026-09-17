import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../config"
import "../../services"
import "../../components"

// Frozen-frame region selector: drag to select, hover a window to snap to
// it, Enter/click confirms, Space toggles save vs copy, Esc cancels.
PanelWindow {
    id: root

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
    property list<var> windows: []   // screen-local rects, topmost first
    property rect sel: Qt.rect(0, 0, 0, 0)
    property bool dragging: false
    property point pressPos
    property var hoverWin: null
    readonly property bool hasSel: sel.width > 2 && sel.height > 2
    readonly property rect shownRect: hasSel ? sel : (hoverWin ? Qt.rect(hoverWin.x, hoverWin.y, hoverWin.w, hoverWin.h) : Qt.rect(0, 0, 0, 0))

    visible: Picker.active
    WlrLayershell.namespace: "desktop-areapicker"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    onVisibleChanged: {
        if (visible) {
            sel = Qt.rect(0, 0, 0, 0);
            hoverWin = null;
            dragging = false;
            capture.captureSource = root.screen;   // binding the screen grabs the frozen frame
            clients.running = true;
            keys.forceActiveFocus();
        } else {
            capture.captureSource = null;
        }
    }

    function windowAt(x: real, y: real): var {
        return windows.find(w => x >= w.x && x < w.x + w.w && y >= w.y && y < w.y + w.h) ?? null;
    }

    function confirm(r: rect): void {
        if (Picker.busy)
            return;
        const x0 = Math.max(0, r.x), y0 = Math.max(0, r.y);
        const w = Math.round(Math.min(root.width, r.x + r.width) - x0);
        const h = Math.round(Math.min(root.height, r.y + r.height) - y0);
        if (w < 1 || h < 1)
            return;
        const sx = capture.sourceSize.width / capture.width, sy = capture.sourceSize.height / capture.height;
        if (!capture.hasContent || !(sx > 0 && sy > 0)) {
            Picker.captureLive(root.screen.x + Math.round(x0), root.screen.y + Math.round(y0), w, h);
            return;
        }
        // snap to whole buffer pixels so the crop maps 1:1 onto the frozen frame
        const px = Math.round(x0 * sx), py = Math.round(y0 * sy);
        const pw = Math.round(w * sx), ph = Math.round(h * sy);
        crop.sourceRect = Qt.rect(px / sx, py / sy, pw / sx, ph / sy);
        crop.textureSize = Qt.size(pw, ph);
        crop.width = w;
        crop.height = h;
        const path = Picker.scratchPath();
        Picker.busy = true;
        // grabToImage multiplies the requested size by the window's device pixel
        // ratio (the output scale), so asking for w x h yields pw x ph pixels
        const scheduled = crop.grabToImage(result => {
            if (!Picker.busy)   // cancelled while the frame was being read back
                return;
            if (result.saveToFile(path)) {
                Picker.deliver(path);
                return;
            }
            console.warn("AreaPicker: cannot write", path);
            Picker.captureLive(root.screen.x + Math.round(x0), root.screen.y + Math.round(y0), w, h);
        }, Qt.size(w, h));
        if (!scheduled)
            Picker.captureLive(root.screen.x + Math.round(x0), root.screen.y + Math.round(y0), w, h);
    }

    Process {
        id: clients

        command: ["hyprctl", "-j", "clients"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const mon = root.monitor;
                    if (!mon)
                        return;
                    const list = JSON.parse(text).filter(c => c.mapped && !c.hidden && c.monitor === mon.id && (c.workspace?.id === mon.activeWorkspace?.id || c.pinned));
                    list.sort((a, b) => a.focusHistoryID - b.focusHistoryID);
                    root.windows = list.map(c => ({
                        x: c.at[0] - mon.x,
                        y: c.at[1] - mon.y,
                        w: c.size[0],
                        h: c.size[1],
                        title: c.title
                    }));
                } catch (e) {
                    console.warn("AreaPicker: cannot parse clients:", e);
                }
            }
        }
    }

    // bound to the screen only while picking: an idle capture of an output
    // that gets unplugged crashes quickshell (QScreen::handle in createContext)
    ScreencopyView {
        id: capture

        anchors.fill: parent
        live: false
        paintCursor: false
    }

    // never shown: confirm() points it at the selection and reads it back
    ShaderEffectSource {
        id: crop

        visible: false
        sourceItem: capture
    }

    // dim everything except the current rectangle
    Item {
        anchors.fill: parent
        visible: capture.hasContent

        Repeater {
            model: [
                Qt.rect(0, 0, root.width, root.shownRect.y),
                Qt.rect(0, root.shownRect.y + root.shownRect.height, root.width, root.height - root.shownRect.y - root.shownRect.height),
                Qt.rect(0, root.shownRect.y, root.shownRect.x, root.shownRect.height),
                Qt.rect(root.shownRect.x + root.shownRect.width, root.shownRect.y, root.width - root.shownRect.x - root.shownRect.width, root.shownRect.height)
            ]

            Rectangle {
                required property rect modelData

                x: modelData.x
                y: modelData.y
                width: Math.max(0, modelData.width)
                height: Math.max(0, modelData.height)
                color: Colours.alpha(Colours.scrim, 0.45)
            }
        }
    }

    Rectangle {
        x: root.shownRect.x
        y: root.shownRect.y
        width: root.shownRect.width
        height: root.shownRect.height
        visible: width > 0 && height > 0
        color: "transparent"
        border.width: 2
        border.color: root.hasSel ? Theme.accent : Colours.tertiary

        Rectangle {
            x: parent.width - width - 6
            y: parent.height - height - 6
            width: sizeLabel.implicitWidth + 14
            height: sizeLabel.implicitHeight + 8
            radius: 6
            color: Colours.alpha(Colours.surfaceContainer, 0.95)
            visible: parent.width > width + 12 && parent.height > height + 12

            StyledText {
                id: sizeLabel

                anchors.centerIn: parent
                text: `${Math.round(root.shownRect.width)} × ${Math.round(root.shownRect.height)}` + (root.hoverWin && !root.hasSel ? `  ${root.hoverWin.title}` : "")
                font.family: Config.fontFamilyMono
                font.pixelSize: Config.fontSize - 1
            }
        }
    }

    // hint pill
    Surface {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 24
        width: hint.implicitWidth + 32
        height: 40
        radius: Theme.outlined ? Theme.radius : 20
        visible: capture.hasContent

        Row {
            id: hint

            anchors.centerIn: parent
            spacing: 10

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: Picker.mode === "copy" ? "content_copy" : "edit"
                color: Theme.accent
                font.pixelSize: Config.iconSize - 3
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: (Picker.mode === "copy" ? "Copy to clipboard" : "Open in satty") + "   ·   drag or click a window   ·   Space: mode   ·   Esc: cancel"
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.CrossCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: mouse => {
            if (mouse.button === Qt.RightButton) {
                Picker.cancel();
                return;
            }
            root.pressPos = Qt.point(mouse.x, mouse.y);
            root.dragging = true;
            root.sel = Qt.rect(0, 0, 0, 0);
        }
        onPositionChanged: mouse => {
            if (root.dragging) {
                const x0 = Math.min(root.pressPos.x, mouse.x), y0 = Math.min(root.pressPos.y, mouse.y);
                root.sel = Qt.rect(x0, y0, Math.abs(mouse.x - root.pressPos.x), Math.abs(mouse.y - root.pressPos.y));
            } else {
                root.hoverWin = root.windowAt(mouse.x, mouse.y);
            }
        }
        onReleased: mouse => {
            if (mouse.button !== Qt.LeftButton || !root.dragging)
                return;
            root.dragging = false;
            if (root.hasSel)
                root.confirm(root.sel);
            else if (root.hoverWin)
                root.confirm(Qt.rect(root.hoverWin.x, root.hoverWin.y, root.hoverWin.w, root.hoverWin.h));
        }
    }

    Item {
        id: keys

        focus: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape)
                Picker.cancel();
            else if (event.key === Qt.Key_Space)
                Picker.toggleMode();
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (root.shownRect.width > 0)
                    root.confirm(root.shownRect);
            } else
                return;
            event.accepted = true;
        }
    }
}
