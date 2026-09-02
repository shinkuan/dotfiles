import QtQuick
import "../../config"
import "../../services"
import "../../components"

BarItem {
    id: item

    popout: "power"

    MaterialIcon {
        anchors.horizontalCenter: Theme.barTop ? undefined : parent.horizontalCenter
        anchors.verticalCenter: Theme.barTop ? parent.verticalCenter : undefined
        text: "power_settings_new"
        color: Idle.inhibited ? item.fgAccent : item.fg
    }
}
