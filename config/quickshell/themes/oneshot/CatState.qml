pragma Singleton

import QtQuick
import Quickshell

// Where the cat is, so there's only ever one: it naps on the bar unless
// it's peeking over a new notification (or sitting in a panel, which the
// bar knows by itself).
Singleton {
    property bool peeking: false
}
