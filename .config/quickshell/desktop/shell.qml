//@ pragma UseQApplication
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1

import QtQuick
import Quickshell
import "services"
import "modules/background"
import "modules/frame"
import "modules/shell"
import "modules/areapicker"
import "modules/launcher"
import "modules/polkit"

ShellRoot {
    // singletons with side effects (IPC handlers, shortcuts, inhibitor
    // surface, pollers) must be touched once to be instantiated
    Component.onCompleted: [Requests, Idle, Vpn, Brightness, ShellState, Audio, Picker, Notifs, Launcher, Players, Polkit]

    Variants {
        model: Quickshell.screens

        Scope {
            id: scope

            required property ShellScreen modelData

            Background {
                screen: scope.modelData
            }

            EdgeFrame {
                screen: scope.modelData
            }

            ShellSurface {
                screen: scope.modelData
            }

            AreaPicker {
                screen: scope.modelData
            }

            LauncherWindow {
                screen: scope.modelData
            }

            PolkitDialog {
                screen: scope.modelData
            }
        }
    }
}
