import QtQuick
import Quickshell.Services.Notifications
import qs.components
import qs.services

// Notification center: do-not-disturb (on, or for an hour), per-app muting,
// and the history. The skin (NotificationsMenu) lays it out; clicking a
// notification runs its action, and it can be dismissed.
Skinned {
    id: root

    property bool open: false

    readonly property var history: Notifs.list.slice().reverse()  // newest first
    readonly property date now: Time.now
    readonly property bool dnd: Notifs.dnd
    readonly property real dndUntil: Notifs.dndUntil  // 0 while it's on until turned off
    readonly property int dndMinutesLeft: dndUntil > 0 ? Math.max(1, Math.ceil((dndUntil - now) / 60000)) : 0
    readonly property var apps: Notifs.apps
    readonly property var mutedApps: Notifs.mutedApps

    skin: "NotificationsMenu"

    function ago(n: var): string {
        const t = Notifs.received[n?.id];
        if (!t)
            return "";
        const m = Math.floor((Time.now - t) / 60000);
        return m < 1 ? "now" : m < 60 ? `${m}m` : m < 1440 ? `${Math.floor(m / 60)}h` : `${Math.floor(m / 1440)}d`;
    }
    // When it came in, or null.
    function receivedAt(n: var): var {
        return Notifs.received[n?.id] ?? null;
    }
    function critical(n: var): bool {
        return n?.urgency === NotificationUrgency.Critical;
    }
    // The body as plain text.
    function plain(n: var): string {
        return (n?.body ?? "").replace(/<[^>]*>/g, "").replace(/\s+/g, " ").trim();
    }
    function invoke(n: var): void {
        n?.actions.find(a => a.identifier === "default")?.invoke();
    }
    function dismiss(n: var): void {
        Notifs.dismiss(n);
    }
    function clear(): void {
        Notifs.clear();
    }
    // Do not disturb: `minutes` 0 for on until turned off.
    function setDnd(on: bool, minutes: int): void {
        Notifs.setDnd(on, minutes);
    }
    function isMuted(app: string): bool {
        return Notifs.isMuted(app);
    }
    function toggleApp(app: string): void {
        Notifs.toggleApp(app);
    }
}
