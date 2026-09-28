pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

// Pending package updates: repos via checkupdates (pacman-contrib, no root,
// uses a temporary database), AUR via yay or paru if installed. Checked once
// shortly after start and again when asked (the control center asks when it
// opens, at most every 30 minutes, or right away after a system upgrade).
Singleton {
    id: root

    // Pending updates per repository: { core: 9, extra: 22, multilib: 2, aur: 0 }.
    // core, extra, multilib and aur are always present; other repos only when
    // they have updates.
    property var counts: ({ core: 0, extra: 0, multilib: 0, aur: 0 })
    readonly property int count: Object.values(counts).reduce((a, b) => a + b, 0)

    property bool checking: false
    property bool failed: false        // last check couldn't reach the mirrors
    property date lastChecked: new Date(0)
    property string lastUpgrade: ""    // ISO time of the last full upgrade (pacman.log)
    property bool checkupdatesMissing: false

    // What "update" runs in a terminal.
    property string aurHelper: ""
    readonly property string upgradeCommand: aurHelper ? aurHelper : "sudo pacman -Syu"

    function check(force: bool): void {
        if (checking)
            return;
        if (!force && Date.now() - lastChecked.getTime() < 30 * 60 * 1000) {
            upgradeProbe.running = true;  // re-check anyway if an upgrade happened since
            return;
        }
        checking = true;
        checker.running = true;
    }

    function upgrade(): void {
        Launcher.runInTerminal(`${upgradeCommand}; echo; read -n1 -rsp "done, press a key"`);
    }

    // First check a minute after start, so the info is there when you look.
    Timer {
        interval: 60000
        running: true
        onTriggered: root.check(true)
    }

    Process {
        id: checker

        command: ["sh", "-c", `
            command -v checkupdates >/dev/null || { echo "missing"; exit; }
            for h in yay paru; do command -v $h >/dev/null && { echo "helper $h"; break; }; done
            out=$(checkupdates 2>/dev/null); code=$?
            echo "code $code"
            # Which repo each update comes from, using checkupdates' fresh database.
            db="\${CHECKUPDATES_DB:-\${TMPDIR:-/tmp}/checkup-db-$(id -u)/}"
            names=$(echo "$out" | awk '{print $1}')
            [ -n "$out" ] && NAMES="$names" pacman -Sl --dbpath "$db" 2>/dev/null | NAMES="$names" awk '
                BEGIN { n = split(ENVIRON["NAMES"], a, "\\n"); for (i = 1; i <= n; i++) want[a[i]] = 1 }
                ($2 in want) { print "repo " $1 }'
            for h in yay paru; do command -v $h >/dev/null && { $h -Qua 2>/dev/null | sed 's/^.*/repo aur/'; break; }; done
            grep 'starting full system upgrade' /var/log/pacman.log | tail -1 | cut -c2-25 | sed 's/^/last /'`]
        stdout: StdioCollector {
            onStreamFinished: {
                const counts = { core: 0, extra: 0, multilib: 0, aur: 0 };
                let code = 0;
                for (const line of text.split("\n")) {
                    if (line === "missing")
                        root.checkupdatesMissing = true;
                    else if (line.startsWith("helper "))
                        root.aurHelper = line.slice(7);
                    else if (line.startsWith("code "))
                        code = parseInt(line.slice(5));
                    else if (line.startsWith("repo ")) {
                        const repo = line.slice(5);
                        counts[repo] = (counts[repo] ?? 0) + 1;
                    }
                    else if (line.startsWith("last "))
                        root.lastUpgrade = line.slice(5);
                }
                // checkupdates: 0 = updates, 2 = none, anything else = failed
                root.failed = code !== 0 && code !== 2;
                if (!root.failed)
                    root.counts = counts;
                root.lastChecked = new Date();
                root.checking = false;
            }
        }
    }

    // Cheap: has a full upgrade happened since the last check?
    Process {
        id: upgradeProbe

        command: ["sh", "-c", "grep 'starting full system upgrade' /var/log/pacman.log | tail -1 | cut -c2-25"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() && text.trim() !== root.lastUpgrade) {
                    root.checking = true;
                    checker.running = true;
                }
            }
        }
    }

    HealthCheck {
        source: "updates"
        ok: !root.checkupdatesMissing
        reason: "checkupdates not found (install pacman-contrib)"
        grace: 0
    }

    // qs ipc call updates <status|check>
    IpcHandler {
        target: "updates"

        function status(): string {
            return root.checking ? "checking…" : root.failed ? "check failed"
                : `${Object.entries(root.counts).map(([r, n]) => `${r} ${n}`).join(", ")}; last upgrade ${root.lastUpgrade || "unknown"}`;
        }
        function check(): void { root.check(true); }
    }
}
