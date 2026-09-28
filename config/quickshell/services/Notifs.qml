pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.core

// Notification daemon (org.freedesktop.Notifications).
//
// On start it takes the bus name over from dunst. Dunst stays installed and
// D-Bus-activated, so it catches notifications while the shell isn't running.
// If another daemon holds the name, the server doesn't start and Health says who.
Singleton {
    id: root

    // Newest last. Kept until dismissed; capped at `historyLimit`.
    readonly property var list: server.item?.trackedNotifications.values ?? []
    readonly property int historyLimit: 50

    // Currently shown as popups, newest first.
    property var popups: []

    // Do not disturb: no popups (critical ones still show). With `dndUntil`
    // set (ms since epoch) it switches itself off at that time.
    property bool dnd: false
    property real dndUntil: 0

    // Apps whose popups are silenced (lowercase names); they still land in the
    // history. Saved in config.json → notifications.mutedApps.
    readonly property var mutedApps: Config.notifications.mutedApps

    // Arrival time per notification id (ms since epoch).
    property var received: ({})

    // Every app in the history, plus muted ones, sorted; one entry per app
    // regardless of case (history names win over the lowercase mute list).
    readonly property var apps: {
        const byKey = {};
        for (const name of [...mutedApps, ...list.map(n => n.appName).filter(a => a)])
            byKey[name.toLowerCase()] = name;
        return Object.values(byKey).sort((a, b) => a.localeCompare(b));
    }

    // While the notification center is open popups would only cover it, so
    // current ones are cleared and new ones aren't shown.
    readonly property bool centerOpen: Panels.isOpen("notifications")
    onCenterOpenChanged: if (centerOpen) popups = []

    function setDnd(on: bool, minutes: int): void {
        dnd = on;
        dndUntil = on && minutes > 0 ? Date.now() + minutes * 60000 : 0;
    }

    function isMuted(app: string): bool {
        return mutedApps.includes(app.toLowerCase());
    }

    function toggleApp(app: string): void {
        const key = app.toLowerCase();
        Config.set("notifications.mutedApps", isMuted(app) ? mutedApps.filter(a => a !== key) : [...mutedApps, key]);
    }

    // Who owns the bus name: "<pid> <process name>", or "" if nobody.
    property string owner: ""
    readonly property bool ok: !!server.item && owner.split(" ")[0] === String(Quickshell.processId)

    function hidePopup(n: Notification): void {
        popups = popups.filter(p => p !== n);
        if (n?.transient)
            n.expire();
    }

    function dismiss(n: Notification): void {
        n?.dismiss();
    }

    function clear(): void {
        for (const n of list.slice())
            n.dismiss();
    }

    // Seconds the popup stays up; 0 = until dismissed.
    function popupTimeout(n: Notification): real {
        if (n.urgency === NotificationUrgency.Critical || n.expireTimeout === 0)
            return 0;
        return n.expireTimeout > 0 ? n.expireTimeout : Config.notifications.timeout;
    }

    // Ends a timed do-not-disturb.
    Timer {
        interval: Math.max(1000, root.dndUntil - Date.now())
        running: root.dnd && root.dndUntil > 0
        onTriggered: root.setDnd(false, 0)
    }

    LazyLoader {
        id: server

        NotificationServer {
            keepOnReload: true
            persistenceSupported: true
            bodySupported: true
            bodyMarkupSupported: true
            actionsSupported: true
            imageSupported: true

            onNotification: n => {
                n.tracked = true;
                n.closed.connect(() => root.popups = root.popups.filter(p => p !== n));
                root.received = Object.assign({}, root.received, { [n.id]: Date.now() });

                const silenced = root.dnd || root.centerOpen || root.isMuted(n.appName);
                if (!silenced || n.urgency === NotificationUrgency.Critical)
                    root.popups = [n, ...root.popups];

                if (root.list.length > root.historyLimit)
                    root.list[0].dismiss();
            }
        }
    }

    // Prints the current owner of the bus name. With "takeover", stops dunst first.
    Process {
        id: busOwner

        property string mode: "takeover"

        running: true
        command: ["sh", "-c", `
            owner() {
                pid=$(busctl --user call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus \
                    GetConnectionUnixProcessID s org.freedesktop.Notifications 2>/dev/null | cut -d' ' -f2)
                [ -n "$pid" ] && echo "$pid $(cat /proc/$pid/comm)"
            }
            if [ "$1" = takeover ] && owner | grep -q ' dunst$'; then
                pkill -x dunst
                for i in $(seq 20); do [ -z "$(owner)" ] && break; sleep 0.1; done
            fi
            owner`, "sh", mode]

        stdout: StdioCollector {
            onStreamFinished: {
                root.owner = text.trim();
                if (busOwner.mode !== "takeover")
                    return;

                // Free, or already ours (shell reload): start the server and verify.
                const pid = root.owner.split(" ")[0];
                if (!pid || pid === String(Quickshell.processId)) {
                    server.active = true;
                    busOwner.mode = "verify";
                    busOwner.running = true;
                }
            }
        }
    }

    HealthCheck {
        source: "notifications"
        ok: root.ok
        reason: root.owner
            ? `org.freedesktop.Notifications is owned by ${root.owner.split(" ")[1]} (pid ${root.owner.split(" ")[0]})`
            : "notification server failed to register"
    }

    // qs ipc call notifications <toggle|open|close|dnd|mute APP|clear|list>
    IpcHandler {
        target: "notifications"

        function toggle(): void { Panels.toggle("notifications"); }
        function open(): void { Panels.open("notifications"); }
        function close(): void {
            if (Panels.isOpen("notifications"))
                Panels.close();
        }

        function dnd(): string {
            root.setDnd(!root.dnd, 0);
            return root.dnd ? "dnd on" : "dnd off";
        }
        function mute(app: string): string {
            root.toggleApp(app);
            return root.isMuted(app) ? `${app} muted` : `${app} unmuted`;
        }
        function clear(): void { root.clear(); }
        function list(): string {
            return root.list.map(n => `[${n.appName}] ${n.summary}${n.body ? ": " + n.body : ""}`).join("\n") || "no notifications";
        }
    }
}
