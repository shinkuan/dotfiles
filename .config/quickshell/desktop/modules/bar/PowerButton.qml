import QtQuick
import "../../config"
import "../../services"
import "../../components"

BarItem {
    popout: "power"

    MaterialIcon {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "power_settings_new"
        color: Idle.inhibited ? Colours.primary : Colours.onSurface
    }
}
