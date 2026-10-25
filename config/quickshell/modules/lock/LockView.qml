import QtQuick
import Quickshell
import qs.components
import qs.core
import qs.services

// What the lock screen shows (used by Lock.qml for each screen): the time;
// on the primary screen also the password prompt (focus always returns to
// it), passcode lamps when Config.passcode is set, and power keys (reboot and
// power off need a second press within 3 s). The skin (LockScreen) draws it,
// with the field; `unlock` checks what's typed in it.
//
// `phase` is where the lock is (see Lock): "locked" on the lock surface;
// "closing", "locked" or "opening" on the transition's overlay, which is
// for show only (`interactive` false: nothing typed there counts).
Skinned {
    id: root

    property bool primary: true
    readonly property int passcode: Config.passcode
    property string armed: ""  // power key waiting for its second press
    property string phase: "locked"
    property bool interactive: true

    readonly property string user: Quickshell.env("USER") ?? ""
    readonly property string hostname: Session.hostname
    readonly property string authState: Session.authState  // "", "checking", "failed"
    readonly property string authMessage: Session.authMessage
    readonly property int failures: Session.failures
    readonly property date now: Time.now
    // Unlocked, the lock screen opening onto the desktop.
    readonly property bool unlocking: phase === "opening"

    // A wrong password (shake, clear the field); locked or unlocked (clear
    // it); put the keys back in the field.
    signal failed
    signal reset
    signal refocusRequested

    skin: "LockScreen"

    // (This view only exists while the screen is locked.)
    function refocus(): void {
        if (primary && interactive)
            refocusRequested();
    }

    function unlock(password: string): void {
        if (interactive)
            Session.unlockWith(password);
    }

    // Typing goes straight into the prompt, no click needed. The field's own
    // first focus can come too early: `primary` is only known once the lock
    // surface has its screen, and keys only arrive once the compositor makes
    // the lock window active. Focus again at both moments.
    readonly property bool windowActive: Window.active
    onPrimaryChanged: refocus()
    onWindowActiveChanged: refocus()

    function power(action: string): void {
        if (!interactive)
            return;
        if (action === "sleep") {
            Session.suspend();
        } else if (armed === action) {
            armed = "";
            action === "reboot" ? Session.reboot() : Session.poweroff();
        } else {
            armed = action;
            disarm.restart();
        }
        refocus();
    }

    Timer {
        id: disarm
        interval: 3000
        onTriggered: root.armed = ""
    }

    Connections {
        target: Session

        function onFailuresChanged(): void {
            if (Session.failures > 0)
                root.failed();
            root.refocus();
        }
        function onLockedChanged(): void {
            root.reset();
            root.armed = "";
            root.refocus();
        }
        function onAuthStateChanged(): void {
            root.refocus();
        }
    }
}
