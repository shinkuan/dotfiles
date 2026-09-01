pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Polkit

// The shell is the session's polkit agent (polkit allows one per
// session; polkit-fallback starts polkit-gnome when the shell is down).
Singleton {
    id: root

    readonly property PolkitAgent agent: PolkitAgent {
        id: agent

        path: "/org/desktop_shell/PolkitAgent"
        onIsRegisteredChanged: {
            if (!isRegistered)
                console.warn("Polkit: agent not registered (another agent may own the session)");
        }
    }
    readonly property AuthFlow flow: agent.flow
    readonly property bool active: agent.isActive && flow !== null && !flow.isCompleted
}
