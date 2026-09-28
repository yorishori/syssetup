pragma Singleton

import QtQuick
import Quickshell

// Current time. `now` ticks every minute; `nowSeconds` ticks every second but
// only while `secondsNeeded` is set (e.g. while the calendar is open).
Singleton {
    id: root

    readonly property date now: clock.date
    readonly property date nowSeconds: fine.date
    property bool secondsNeeded: false

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
