//@ pragma UseQApplication
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1

import QtQuick
import Quickshell
import "modules/background"
import "modules/frame"
import "modules/shell"

ShellRoot {
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
        }
    }
}
