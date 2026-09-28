import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.core
import qs.services

// Lock screen (Wayland session lock). Locked/unlocked and the password check
// live in the Session service; this only draws. The primary screen gets the
// console with a password prompt; other screens just the clock.
Scope {
    // Idle locking and screen blanking live in the Idle service; referencing
    // it here starts it.
    readonly property bool screenOff: Idle.screenOff

    WlSessionLock {
        id: lock

        locked: Session.locked

        WlSessionLockSurface {
            id: surface

            color: Config.colors.bg

            LockView {
                anchors.fill: parent
                primary: surface.screen === Display.primary
            }
        }
    }

    // Tell Session when the compositor has confirmed the lock.
    Binding {
        target: Session
        property: "lockSecure"
        value: lock.secure
    }
}
