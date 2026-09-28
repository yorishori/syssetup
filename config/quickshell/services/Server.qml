pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

// Home server status (config.json → server): is the machine up (ping), and
// does each service answer (HTTP)? Checked when asked (the control center
// asks when it opens), never in the background. A service counts as up if it
// answers at all below 500 (a login page is still "up").
Singleton {
    id: root

    readonly property var server: Config.server
    readonly property bool configured: !!server.host

    property bool checking: false
    property string host: ""      // "up", "down" or "" (not checked yet)
    property var services: ({})   // { name: "up" | "down" }
    property date lastChecked: new Date(0)

    readonly property bool allUp: host === "up" && server.services.every(s => services[s.name] === "up")

    function check(): void {
        if (!configured || checker.running)
            return;
        checking = true;
        const args = [];
        for (const s of server.services)
            args.push(s.name, s.url);
        checker.command = ["sh", "-c", `
            host="$1"; shift
            ping -c1 -W1 "$host" >/dev/null 2>&1 && echo "host up" || echo "host down" &
            while [ $# -ge 2 ]; do
                (code=$(curl -s -o /dev/null -m 3 -w '%{http_code}' "$2"); echo "svc $code $1") &
                shift 2
            done
            wait`, "sh", server.host, ...args];
        checker.running = true;
    }

    function open(url: string): void {
        Quickshell.execDetached(["xdg-open", url]);
    }

    Process {
        id: checker

        stdout: StdioCollector {
            onStreamFinished: {
                const services = {};
                for (const line of text.split("\n")) {
                    const f = line.split(" ");
                    if (f[0] === "host")
                        root.host = f[1];
                    else if (f[0] === "svc") {
                        const code = parseInt(f[1]) || 0;
                        services[f.slice(2).join(" ")] = code > 0 && code < 500 ? "up" : "down";
                    }
                }
                root.services = services;
                root.lastChecked = new Date();
                root.checking = false;
            }
        }
    }

    // qs ipc call server <check|status>
    IpcHandler {
        target: "server"

        function check(): void { root.check(); }
        function status(): string {
            if (!root.configured)
                return "no server configured";
            const svc = root.server.services.map(s => `${s.name} ${root.services[s.name] ?? "?"}`).join(", ");
            return `${root.server.name || root.server.host}: ${root.host || "?"}${svc ? "; " + svc : ""}`;
        }
    }
}
