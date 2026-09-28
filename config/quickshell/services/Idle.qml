pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.core

// Idle, instead of swayidle or hypridle: lock after idle.lock minutes without input, turn
// the display off after idle.screenOff minutes (back on at the first input).
// Apps that inhibit idle (video players, games) hold both off. 0 = never.
// Caffeinated (the bar's cup): neither happens until it's switched off.
Singleton {
    id: root

    readonly property int lockAfter: Config.idle.lock ?? 0          // minutes
    readonly property int screenOffAfter: Config.idle.screenOff ?? 0  // minutes
    property bool screenOff: false
    property bool caffeinated: false

    // Quickshell ignores timeout changes on a live monitor, so re-arm it.
    component Monitor: IdleMonitor {
        property int minutes

        enabled: minutes > 0 && !root.caffeinated
        timeout: minutes * 60
        onTimeoutChanged: {
            if (enabled) {
                enabled = false;
                enabled = Qt.binding(() => minutes > 0 && !root.caffeinated);
            }
        }
    }

    Monitor {
        id: lockIdle

        minutes: root.lockAfter
        onIsIdleChanged: {
            if (isIdle && !Session.locked)
                Session.lock();
        }
    }

    Monitor {
        id: screenIdle

        minutes: root.screenOffAfter
        onIsIdleChanged: {
            if (isIdle === root.screenOff)
                return;
            root.screenOff = isIdle;
            Wm.dpms(!isIdle);
        }
    }

    // qs ipc call idle <status|caffeinate>
    IpcHandler {
        target: "idle"

        function status(): string {
            const step = (min, idle) => min > 0 ? `after ${min} min${idle ? " (idle now)" : ""}` : "never";
            return `lock: ${step(root.lockAfter, lockIdle.isIdle)}\nscreen off: ${step(root.screenOffAfter, screenIdle.isIdle)}`
                + (root.caffeinated ? "\ncaffeinated: neither until it's switched off" : "");
        }
        function caffeinate(): string {
            root.caffeinated = !root.caffeinated;
            return root.caffeinated ? "caffeinated" : "not caffeinated";
        }
    }
}
