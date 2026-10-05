pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.core

// Idle, instead of swayidle or hypridle: lock after idle.lock minutes without input, turn
// the display off after idle.screenOff minutes (back on at the first input).
// Apps that inhibit idle (fullscreen windows, games) hold both off, and so does
// any playing media player (windowed browser video asks over D-Bus, which
// nothing here answers). 0 = never.
// Caffeinated (the bar's cup): neither happens until it's switched off.
// `idle` turns on after idle.indicator seconds of the same idling, for the
// bar's sleep glyph.
Singleton {
    id: root

    readonly property int lockAfter: Config.idle.lock ?? 0          // minutes
    readonly property int screenOffAfter: Config.idle.screenOff ?? 0  // minutes
    readonly property int indicatorAfter: Config.idle.indicator ?? 0  // seconds
    property bool screenOff: false
    property bool caffeinated: false
    readonly property bool held: caffeinated || Media.playingPlayer !== null
    readonly property bool idle: indicatorIdle.isIdle

    // Quickshell ignores timeout changes on a live monitor, so re-arm it.
    component Monitor: IdleMonitor {
        property int seconds

        enabled: seconds > 0 && !root.held
        timeout: seconds
        onTimeoutChanged: {
            if (enabled) {
                enabled = false;
                enabled = Qt.binding(() => seconds > 0 && !root.held);
            }
        }
    }

    Monitor {
        id: lockIdle

        seconds: root.lockAfter * 60
        onIsIdleChanged: {
            if (isIdle && !Session.locked)
                Session.lock();
        }
    }

    Monitor {
        id: screenIdle

        seconds: root.screenOffAfter * 60
        onIsIdleChanged: {
            if (isIdle === root.screenOff)
                return;
            root.screenOff = isIdle;
            Wm.dpms(!isIdle);
        }
    }

    Monitor {
        id: indicatorIdle

        seconds: root.indicatorAfter
    }

    // qs ipc call idle <status|caffeinate>
    IpcHandler {
        target: "idle"

        function status(): string {
            const step = (min, idle) => min > 0 ? `after ${min} min${idle ? " (idle now)" : ""}` : "never";
            return `lock: ${step(root.lockAfter, lockIdle.isIdle)}\nscreen off: ${step(root.screenOffAfter, screenIdle.isIdle)}`
                + (root.caffeinated ? "\ncaffeinated: neither until it's switched off"
                    : Media.playingPlayer ? "\nmedia playing: neither while it plays" : "");
        }
        function caffeinate(): string {
            root.caffeinated = !root.caffeinated;
            return root.caffeinated ? "caffeinated" : "not caffeinated";
        }
    }
}
