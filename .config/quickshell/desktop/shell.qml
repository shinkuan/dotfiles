//@ pragma UseQApplication
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1
// Qt sizes the texture atlas to the next power of two of the window (64 MiB
// for a 4K surface) and gives every window depth/stencil buffers it never uses
//@ pragma Env QSG_ATLAS_WIDTH=1024
//@ pragma Env QSG_ATLAS_HEIGHT=1024
//@ pragma Env QSG_NO_DEPTH_BUFFER=1
//@ pragma Env QSG_NO_STENCIL_BUFFER=1

import QtQuick
import Quickshell
import "services"
import "modules/background"
import "modules/frame"
import "modules/shell"
import "modules/areapicker"
import "modules/launcher"
import "modules/polkit"
import "modules/overview"
import "modules/summon"

ShellRoot {
    // singletons with side effects (IPC handlers, shortcuts, inhibitor
    // surface, pollers) must be touched once to be instantiated
    Component.onCompleted: [Requests, Idle, Vpn, Brightness, ShellState, Audio, Picker, Notifs, Launcher, Players, Polkit, Overview, Battery, Summon, GameMode]

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

            OverviewWindow {
                screen: scope.modelData
            }

            SummonWindow {
                screen: scope.modelData
            }
        }
    }
}
