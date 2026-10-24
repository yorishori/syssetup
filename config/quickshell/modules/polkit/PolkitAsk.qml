import QtQuick
import qs.components
import qs.services

// The admin password prompt's behaviour (the agent lives in
// services/Polkit): the request, who you authenticate as, the response.
// Enter authorizes (the skin's field calls `submit`), Escape cancels; a
// wrong one sends `denied` and asks again. `refocusRequested` asks the
// skin to put the keys back in its field (it never lets them go).
Skinned {
    id: root

    readonly property var flow: Polkit.flow
    readonly property bool active: Polkit.active
    readonly property var identities: flow?.identities ?? []
    readonly property var identity: flow?.selectedIdentity ?? null
    readonly property bool failed: flow?.failed ?? false
    readonly property bool hidden: !(flow?.responseVisible ?? false)
    property bool checking: false

    signal denied
    signal refocusRequested

    skin: "PolkitMenu"

    function nameOf(id: var): string {
        return id ? (id.displayName || id.name) : "";
    }
    // Whether it went (not while one's being checked, or none's asked for).
    function submit(response: string): bool {
        if (!flow?.isResponseRequired || checking)
            return false;
        checking = true;
        Polkit.submit(response);
        return true;
    }
    function cancel(): void {
        Polkit.cancel();
    }
    function choose(id: var): void {
        flow.selectedIdentity = id;
        refocusRequested();
    }
    function refocus(): void {
        refocusRequested();
    }

    onActiveChanged: {
        checking = false;
        Qt.callLater(refocus);
    }

    Connections {
        target: root.flow
        ignoreUnknownSignals: true

        function onAuthenticationFailed(): void {
            root.checking = false;
            root.denied();
            root.refocus();
        }
        function onIsResponseRequiredChanged(): void {
            if (root.flow.isResponseRequired)
                root.checking = false;
            root.refocus();
        }
    }
}
