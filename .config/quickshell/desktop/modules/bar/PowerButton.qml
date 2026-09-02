import QtQuick
import "../../config"
import "../../services"
import "../../components"

BarItem {
    id: item

    popout: "power"

    MaterialIcon {
        text: "power_settings_new"
        color: Idle.inhibited ? item.fgAccent : item.fg
    }
}
