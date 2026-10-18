import QtQuick
import qs.components as C
import qs.core

// A card floating a little above the screen edge, on a soft shadow; it pops
// up with a bounce.
Item {
    id: root

    required property C.BottomDrawer control

    readonly property real overhang: 0
    readonly property real lift: 12
    property real shownHeight: control.open ? control.openHeight : 0
    property real contentOpacity: control.open ? 1 : 0
    property real popScale: control.open ? 1 : 0.8

    Behavior on shownHeight {
        NumberAnimation {
            duration: root.control.open ? 420 : 160
            easing.type: root.control.open ? Theme.motion.spring : Easing.InCubic
            easing.overshoot: Theme.motion.bounce / 2
        }
    }
    Behavior on contentOpacity {
        NumberAnimation { duration: root.control.open ? 200 : 80 }
    }
    Behavior on popScale {
        NumberAnimation { duration: 460; easing.type: Theme.motion.spring; easing.overshoot: Theme.motion.bounce }
    }

    Box {
        anchors.fill: parent
        fill: Theme.palette.bg
        raised: true
    }
}
