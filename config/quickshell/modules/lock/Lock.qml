import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.services

// Lock screen (Wayland session lock). Locked/unlocked and the password check
// live in the Session service; this only draws. The primary screen gets the
// console with a password prompt; other screens just the clock.
//
// A theme can have the lock close over the live desktop and open onto it
// (its Spec's layout.lockClose / lockOpen, in ms, at most a second each):
//   closing  the theme's lock screen plays on an overlay above everything;
//            the session lock goes up once it's done
//   locked   the session lock is up; the overlay stays mapped beneath it,
//            showing the closed lock screen, so the moment the lock lets go
//            the compositor has that to show (not a blank frame)
//   opening  the session lock is gone; the overlay plays the lock screen
//            opening onto the desktop, then goes
// Nothing of the desktop is ever captured. Locking for sleep (Session's
// `now`) skips the closing; so does a theme without these.
Scope {
    id: root

    // Idle locking and screen blanking live in the Idle service (started by
    // modules/daemons).
    readonly property bool screenOff: Idle.screenOff

    readonly property int closeTime: Math.min(Theme.values.layout?.lockClose ?? 0, 1000)
    readonly property int openTime: Math.min(Theme.values.layout?.lockOpen ?? 0, 1000)
    readonly property bool transitions: closeTime > 0 || openTime > 0

    // "", "closing", "locked" or "opening".
    property string phase: ""

    function update(): void {
        if (Session.locked) {
            opening.stop();
            if (phase === "" && closeTime > 0 && !Session.now) {
                phase = "closing";
                closing.restart();
            } else if (phase !== "closing") {
                phase = "locked";
            }
        } else {
            closing.stop();
            if (phase === "locked" && openTime > 0) {
                phase = "opening";
                opening.restart();
            } else {
                phase = "";
            }
        }
    }

    Component.onCompleted: update()
    Connections {
        target: Session

        function onLockedChanged(): void {
            root.update();
        }
    }
    Timer {
        id: closing

        interval: root.closeTime
        onTriggered: root.phase = "locked"
    }
    Timer {
        id: opening

        interval: root.openTime
        onTriggered: root.phase = ""
    }

    // The transition's overlay, one per screen.
    Variants {
        model: root.transitions && root.phase !== "" ? Quickshell.screens : []

        PanelWindow {
            id: overlay

            required property ShellScreen modelData

            screen: modelData
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-lock-transition"
            // Never changed while it's up: changing a surface's keyboard mode
            // or input region while the lock covers it makes it come back
            // blank for a frame when the lock lets go. Input is the
            // catcher's (below).
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            mask: Region {}

            LockView {
                anchors.fill: parent
                primary: overlay.screen === Display.primary
                phase: root.phase
                interactive: false
            }
        }
    }

    // While closing, the keyboard and every click go here, so nothing
    // reaches the windows the lock is closing over.
    Variants {
        model: root.phase === "closing" ? Quickshell.screens : []

        PanelWindow {
            required property ShellScreen modelData

            screen: modelData
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-lock-catcher"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
            }
        }
    }

    WlSessionLock {
        id: lock

        locked: root.phase === "locked"

        WlSessionLockSurface {
            id: surface

            color: Theme.palette?.bg ?? "black"

            LockView {
                id: view

                anchors.fill: parent
                primary: surface.screen === Display.primary
            }
            // The theme's lock screen couldn't load: a plain one, so the lock
            // can always be opened.
            PlainLock {
                anchors.fill: parent
                visible: view.skinFailed
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
