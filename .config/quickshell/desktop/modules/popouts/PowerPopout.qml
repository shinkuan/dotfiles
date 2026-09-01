import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import "../../config"
import "../../services"
import "../../components"

ColumnLayout {
    id: root

    property string armed: ""
    readonly property bool laptop: UPower.displayDevice?.isLaptopBattery ?? false

    width: Config.popouts.width
    spacing: 8

    Timer {
        id: disarm

        interval: 3000
        onTriggered: root.armed = ""
    }

    function profileIcon(p: int): string {
        return p === PowerProfile.Performance ? "speed" : p === PowerProfile.PowerSaver ? "energy_savings_leaf" : "balance";
    }

    function profileName(p: int): string {
        return p === PowerProfile.Performance ? "Performance" : p === PowerProfile.PowerSaver ? "Power saver" : "Balanced";
    }

    component ToggleTile: Clickable {
        id: tile

        property string icon: ""
        property string label: ""
        property string detail: ""
        property bool checked: false

        Layout.fillWidth: true
        implicitHeight: 56
        radius: Config.radius + 2
        baseColor: checked ? Colours.primary : Colours.surfaceContainerHighest
        hoverColor: checked ? Colours.mix(Colours.primary, Colours.onPrimary, 0.1) : Colours.mix(Colours.surfaceContainerHighest, Colours.onSurface, 0.08)
        pressColor: checked ? Colours.mix(Colours.primary, Colours.onPrimary, 0.2) : Colours.mix(Colours.surfaceContainerHighest, Colours.onSurface, 0.14)

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            MaterialIcon {
                text: tile.icon
                fill: tile.checked
                color: tile.checked ? Colours.onPrimary : Colours.onSurfaceVariant
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: tile.label
                    color: tile.checked ? Colours.onPrimary : Colours.onSurface
                    font.weight: Font.DemiBold
                }

                StyledText {
                    Layout.fillWidth: true
                    text: tile.detail
                    color: tile.checked ? Colours.alpha(Colours.onPrimary, 0.8) : Colours.onSurfaceVariant
                    font.pixelSize: Config.fontSize - 2
                }
            }
        }
    }

    component SessionButton: Clickable {
        id: sbtn

        property string icon: ""
        property string label: ""
        property bool danger: false
        readonly property bool isArmed: root.armed === label

        Layout.fillWidth: true
        implicitHeight: 62
        radius: Config.radius + 2
        baseColor: isArmed ? Colours.error : Colours.surfaceContainerHighest
        hoverColor: isArmed ? Colours.mix(Colours.error, Colours.onError, 0.1) : Colours.mix(Colours.surfaceContainerHighest, Colours.onSurface, 0.08)
        pressColor: isArmed ? Colours.mix(Colours.error, Colours.onError, 0.2) : Colours.mix(Colours.surfaceContainerHighest, Colours.onSurface, 0.14)

        signal activated()

        onClicked: {
            if (!danger || isArmed) {
                root.armed = "";
                activated();
            } else {
                root.armed = label;
                disarm.restart();
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 2

            MaterialIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: sbtn.isArmed ? "check" : sbtn.icon
                color: sbtn.isArmed ? Colours.onError : sbtn.danger ? Colours.error : Colours.onSurface
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: sbtn.isArmed ? "Sure?" : sbtn.label
                color: sbtn.isArmed ? Colours.onError : Colours.onSurfaceVariant
                font.pixelSize: Config.fontSize - 2
            }
        }
    }

    SectionLabel {
        text: "Quick settings"
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 8
        rowSpacing: 8

        ToggleTile {
            icon: "coffee"
            label: "Keep awake"
            detail: Idle.keepAwake ? "Idle lock disabled" : Idle.inhibited ? "Inhibited by " + (Idle.joystickActive ? "controller" : "audio") : "Normal"
            checked: Idle.keepAwake
            onClicked: Idle.toggle()
        }

        ToggleTile {
            icon: "do_not_disturb_on"
            label: "Do not disturb"
            detail: ShellState.dnd ? "Popups silenced" : "Popups shown"
            checked: ShellState.dnd
            onClicked: ShellState.toggle("dnd")
        }

        ToggleTile {
            icon: "schedule"
            label: "Desktop clock"
            detail: ShellState.desktopClock ? "Shown on wallpaper" : "Hidden"
            checked: ShellState.desktopClock
            onClicked: ShellState.toggle("desktopClock")
        }

        ToggleTile {
            icon: root.profileIcon(PowerProfiles.profile)
            label: root.profileName(PowerProfiles.profile)
            detail: "Power profile"
            checked: PowerProfiles.profile === PowerProfile.Performance
            onClicked: {
                const order = [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance];
                let i = (order.indexOf(PowerProfiles.profile) + 1) % order.length;
                if (order[i] === PowerProfile.Performance && !PowerProfiles.hasPerformanceProfile)
                    i = 0;
                PowerProfiles.profile = order[i];
            }
        }
    }

    ListItem {
        visible: root.laptop
        Layout.fillWidth: true
        icon: UPower.onBattery ? "battery_5_bar" : "battery_charging_full"
        title: `Battery ${Math.round((UPower.displayDevice?.percentage ?? 0) * 100)}%`
        subtitle: {
            const d = UPower.displayDevice;
            if (!d)
                return "";
            const secs = UPower.onBattery ? d.timeToEmpty : d.timeToFull;
            if (!secs)
                return UPower.onBattery ? "Discharging" : "Charging";
            const h = Math.floor(secs / 3600), m = Math.round((secs % 3600) / 60);
            return (UPower.onBattery ? "" : "Full in ") + (h ? `${h} h ` : "") + `${m} min` + (UPower.onBattery ? " left" : "");
        }
    }

    SectionLabel {
        Layout.topMargin: 4
        text: "Session"
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        SessionButton {
            icon: "lock"
            label: "Lock"
            onActivated: Session.lock()
        }

        SessionButton {
            icon: "bedtime"
            label: "Sleep"
            onActivated: Session.suspend()
        }

        SessionButton {
            icon: "logout"
            label: "Log out"
            danger: true
            onActivated: Session.logout()
        }

        SessionButton {
            icon: "restart_alt"
            label: "Reboot"
            danger: true
            onActivated: Session.reboot()
        }

        SessionButton {
            icon: "power_settings_new"
            label: "Shut down"
            danger: true
            onActivated: Session.shutdown()
        }
    }
}
