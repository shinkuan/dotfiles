pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Polkit

// The shell is the session's polkit agent (polkit allows one per session;
// polkit-fallback starts polkit-gnome when the shell is down).
//
// quickshell registers once and never retries, and after a crash the relaunched
// shell races the core dump of its old self, which still owns the registration
// for a second or two. The agent does re-register when its path changes across
// a reload, so a failed registration is retried by reloading with a new path
// suffix, a few times at most.
Singleton {
    id: root

    readonly property int maxAttempts: 3
    property PolkitAgent agent: null
    readonly property AuthFlow flow: agent?.flow ?? null
    readonly property bool active: (agent?.isActive ?? false) && flow !== null && !flow.isCompleted

    PersistentProperties {
        id: persist

        reloadableId: "polkitRegistration"
        property int attempt: 0

        // fires once the values came over from the previous generation
        onLoaded: {
            const suffix = attempt > 0 ? `_${attempt}` : "";
            root.agent = agentComponent.createObject(root, {
                path: `/org/desktop_shell/PolkitAgent${suffix}`
            });
        }
    }

    Component {
        id: agentComponent

        PolkitAgent {}
    }

    Timer {
        interval: 3000 * (persist.attempt + 1)
        running: root.agent !== null && !root.agent.isRegistered
        onTriggered: {
            if (persist.attempt >= root.maxAttempts) {
                console.warn("Polkit: agent still not registered, giving up (another agent may own the session)");
                return;
            }
            persist.attempt++;
            console.warn(`Polkit: agent not registered, reloading to retry (${persist.attempt}/${root.maxAttempts})`);
            Quickshell.reload(false);
        }
    }
}
