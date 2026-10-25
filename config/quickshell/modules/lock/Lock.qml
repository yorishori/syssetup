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

    // A snapshot of each screen as it was just before locking, for a lock
    // screen that closes over the desktop and opens onto it again (the
    // theme's layout.lockSnapshot): the lock can't show what's under it.
    // Kept in memory only, while locked: { screen name: ItemGrabResult }.
    readonly property bool snapshots: Theme.values.layout?.lockSnapshot ?? false
    property var shots: ({})
    property bool capturing: false

    // When a panel last closed: one still going away (locking from the
    // session menu closes it) is let go before the snapshot.
    property real panelsClosedAt: 0

    function snapshot(): void {
        shots = {};
        capturing = true;
        snapTimeout.restart();
    }
    function engage(): void {
        capturing = false;
        settle.stop();
        snapTimeout.stop();
        held = true;
    }

    Component.onCompleted: held = Session.locked
    Connections {
        target: Session

        function onLockedChanged(): void {
            if (Session.locked) {
                release.stop();
                if (root.snapshots && !root.held) {
                    const settling = 500 - (Date.now() - root.panelsClosedAt);
                    if (settling > 0) {
                        settle.interval = settling;
                        settle.restart();
                    } else {
                        root.snapshot();
                    }
                } else {
                    root.engage();
                }
            } else if (!root.held) {
                // Unlocked before it had locked (still taking snapshots).
                root.capturing = false;
                settle.stop();
                snapTimeout.stop();
                root.shots = {};
            } else if (root.unlockHold > 0) {
                release.restart();
            } else {
                root.held = false;
                root.shots = {};
            }
        }
    }
    Timer {
        id: release

        interval: root.unlockHold
        onTriggered: {
            root.held = false;
            root.shots = {};
        }
    }
    Connections {
        target: Panels

        function onCurrentChanged(): void {
            if (Panels.current === "")
                root.panelsClosedAt = Date.now();
        }
    }
    Timer {
        id: settle

        onTriggered: root.snapshot()
    }
    // Whatever's been taken by then, lock anyway.
    Timer {
        id: snapTimeout

        interval: 400
        onTriggered: root.engage()
    }

    // Taking the snapshots: each screen's frame, frozen, on a click-through
    // overlay (it looks just like what's under it), copied out, then the
    // lock goes up.
    Variants {
        model: root.capturing ? Quickshell.screens : []

        PanelWindow {
            id: snap

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
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-lock-snapshot"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            ScreencopyView {
                id: frame

                anchors.fill: parent
                captureSource: snap.modelData
                live: false
                paintCursor: false
                onHasContentChanged: {
                    if (!hasContent)
                        return;
                    const dpr = snap.modelData.devicePixelRatio ?? 1;
                    grabToImage(result => {
                        if (!root.capturing)
                            return;
                        root.shots = Object.assign({}, root.shots, { [snap.modelData.name]: result });
                        if (Object.keys(root.shots).length >= Quickshell.screens.length)
                            root.engage();
                    }, Qt.size(Math.round(width * dpr), Math.round(height * dpr)));
                }
            }
        }
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
                snapshot: root.shots[surface.screen?.name]?.url ?? ""
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
