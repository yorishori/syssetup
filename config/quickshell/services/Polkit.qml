pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Polkit
import qs.core

// Polkit agent: when something asks for admin rights (pkexec, systemctl, an
// app's "unlock" button), polkit hands the password prompt to us and the
// polkit module shows it. There can be one agent per session: if another one
// (hyprpolkitagent, polkit-gnome) registered first, Health says so.
Singleton {
    id: root

    readonly property AuthFlow flow: agent.flow
    readonly property bool active: agent.isActive && !!agent.flow
    readonly property bool registered: agent.isRegistered

    function submit(response: string): void {
        flow?.submit(response);
    }

    function cancel(): void {
        flow?.cancelAuthenticationRequest();
    }

    PolkitAgent {
        id: agent
    }

    HealthCheck {
        source: "polkit"
        ok: agent.isRegistered
        reason: "not the polkit agent (is another one running, e.g. hyprpolkitagent?); admin prompts won't show here"
        grace: 5000
    }

    // qs ipc call polkit <status|cancel>
    IpcHandler {
        target: "polkit"

        function status(): string {
            if (!root.registered)
                return "not registered";
            return root.active ? `asking: ${root.flow.message} (${root.flow.actionId})` : "idle";
        }
        function cancel(): void { root.cancel(); }
    }
}
