import QtQuick
import qs.core
import qs.modules.bar as B

// Grows out of the bar in the same color, rounded at the bottom (square on
// a flush side). Unrolls with a spring.
Item {
    id: root

    required property B.Drop control

    readonly property real overhang: 0
    property real shownHeight: control.open ? control.openHeight : 0
    property real contentOpacity: control.open ? 1 : 0

    Behavior on shownHeight {
        NumberAnimation {
            duration: root.control.open ? 300 : 150
            easing.type: root.control.open ? Theme.motion.spring : Easing.InQuad
            easing.overshoot: 0.9
        }
    }
    Behavior on contentOpacity {
        NumberAnimation { duration: root.control.open ? 180 : 60 }
    }

    Box {
        id: body

        anchors.fill: parent
    }
    // Square off the top, where it meets the bar, and any flush side.
    Rectangle {
        width: parent.width
        height: Math.min(body.radius, parent.height)
        color: Theme.palette.bg
    }
    Rectangle {
        x: root.control.flushLeft ? 0 : parent.width - width
        width: body.radius
        height: parent.height
        color: Theme.palette.bg
        visible: root.control.flushLeft || root.control.flushRight
    }
}
