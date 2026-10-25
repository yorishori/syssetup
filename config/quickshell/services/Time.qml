pragma Singleton

import QtQuick
import Quickshell

// Current time. `now` ticks every minute; `nowSeconds` ticks every second but
// only while something shows seconds (a `Live { target: Time }`, e.g. the
// calendar while open).
Singleton {
    id: root

    readonly property date now: clock.date
    readonly property date nowSeconds: fine.date
    property int users: 0
    readonly property bool secondsNeeded: users > 0

    function format(fmt: string): string {
        return Qt.formatDateTime(clock.date, fmt);
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    SystemClock {
        id: fine
        precision: SystemClock.Seconds
        enabled: root.secondsNeeded
    }
}
