import QtQuick
import "../../config"
import "../../services"
import "../../components"

BarItem {
    id: item

    popout: "power"

    MaterialIcon {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "power_settings_new"
        color: Idle.inhibited ? item.fgAccent : item.fg
    }
}
