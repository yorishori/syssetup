pragma Singleton

import QtQuick
import Quickshell

// Where the cat is, so there's only ever one: it lives on the bar (BarCat)
// unless it's peeking over a new notification, or lying on an open panel's
// edge, which that panel draws (over its own frame, so the tail can hang
// over it): `perch` the panel's name, `perchX` where along it (in the bar's
// coordinates), `perchFlip` which way it faces.
Singleton {
    property bool peeking: false
    property string perch: ""
    property real perchX: 0
    property bool perchFlip: false
}
