import QtQuick
import Quickshell.Services.Notifications
import qs.components
import qs.core
import qs.services

// The notification popups, newest first. The skin (PopupStack) shows them
// and tells the window what takes input (`inputArea`); each hides after its
// timeout (`timeout`, seconds; 0 stays) unless held, and can be dismissed.
Skinned {
    id: root

    readonly property var popups: Notifs.popups
    // A fullscreen window covers the bar.
    readonly property bool fullscreen: Wm.fullscreen
    readonly property real barHeight: Theme.barHeight
    // Where the bar's notification counter is across the screen; -1 if not.
    readonly property real slotX: Notifs.slotX

    skin: "PopupStack"

    function timeout(n: var): real {
        return n ? Notifs.popupTimeout(n) : 0;
    }
    function hide(n: var): void {
        Notifs.hidePopup(n);
    }
    function dismiss(n: var): void {
        Notifs.dismiss(n);
    }
    function invoke(n: var): void {
        n?.actions.find(a => a.identifier === "default")?.invoke();
    }
    function critical(n: var): bool {
        return n?.urgency === NotificationUrgency.Critical;
    }
    // When it came in, or null.
    function receivedAt(n: var): var {
        return Notifs.received[n?.id] ?? null;
    }
    // The body as plain text.
    function plain(n: var): string {
        return (n?.body ?? "").replace(/<[^>]*>/g, "").replace(/\s+/g, " ").trim();
    }
}
