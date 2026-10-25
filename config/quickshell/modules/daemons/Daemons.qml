import QtQuick
import Quickshell
import qs.services

// Starts the services that stand in for system daemons. A singleton exists
// only once something references it, so without this they would run only
// because some UI happens to read them: auto-lock and screen blanking only if
// the lock module loaded, the notification server only if the popups did.
// Loaded in isolation like any module, so a broken service is reported to
// Health instead of stopping the others.
Scope {
    readonly property var running: [
        Session,  // logind: lock before sleep
        Idle,     // auto-lock and screen blanking
        Notifs,   // the notification server
        Polkit    // the polkit agent
    ]
}
