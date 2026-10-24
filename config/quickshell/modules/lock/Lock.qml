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
    id: root

    // Idle locking and screen blanking live in the Idle service; referencing
    // it here starts it.
    readonly property bool screenOff: Idle.screenOff

    // Locked, and kept so a moment after unlocking while the theme's lock
    // screen opens (its layout.unlockHold, in ms): the lock's not let go
    // until it has.
    property bool held: false
    readonly property int unlockHold: Theme.values.layout?.unlockHold ?? 0

    Component.onCompleted: held = Session.locked
    Connections {
        target: Session

        function onLockedChanged(): void {
            if (Session.locked) {
                release.stop();
                root.held = true;
            } else if (root.unlockHold > 0) {
                release.restart();
            } else {
                root.held = false;
            }
        }
    }
    Timer {
        id: release

        interval: root.unlockHold
        onTriggered: root.held = false
    }

    WlSessionLock {
        id: lock

        locked: root.held

        WlSessionLockSurface {
            id: surface

            color: Theme.palette.bg

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
