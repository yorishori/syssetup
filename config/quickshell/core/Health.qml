pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Central registry of things that are broken.
//
// Any module or service that fails calls report(source, reason); when it
// recovers it calls resolve(source). Nothing here ever throws: a failing part
// of the shell is recorded and announced, everything else keeps running.
Singleton {
    id: root

    // { source: reason }. Reassigned (never mutated) so bindings update.
    property var issues: ({})
    readonly property int count: Object.keys(issues).length

    // Desktop alerts wait until startup is done, so they reach our own
    // notification server instead of waking the fallback daemon (dunst).
    property bool started: false

    function report(source: string, reason: string): void {
        if (issues[source] === reason)
            return;

        const isNew = !(source in issues);
        issues = Object.assign({}, issues, { [source]: reason });
        console.warn(`[health] ${source} is down: ${reason}`);

        if (isNew && started)
            alert(source, reason);
    }

    function alert(source: string, reason: string): void {
        Quickshell.execDetached(["notify-send", "-u", "critical", "-a", "qs", `${source} is down`, reason]);
    }

    function resolve(source: string): void {
        if (!(source in issues))
            return;

        const next = Object.assign({}, issues);
        delete next[source];
        issues = next;
        console.info(`[health] ${source} recovered`);
    }

    Timer {
        interval: 3000
        running: true
        onTriggered: {
            root.started = true;
            for (const [source, reason] of Object.entries(root.issues))
                root.alert(source, reason);
        }
    }

    // `qs ipc call health list`
    IpcHandler {
        target: "health"

        function list(): string {
            const entries = Object.entries(root.issues);
            return entries.length ? entries.map(([s, r]) => `${s}: ${r}`).join("\n") : "all ok";
        }
    }
}
