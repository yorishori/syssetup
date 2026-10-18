import QtQuick
import qs.components as C
import qs.core

// Rises from the screen edge, rounded at the top. Unrolls with a spring.
Item {
    id: root

    required property C.BottomDrawer control

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
        stroke: Theme.palette.border
    }
    // Square off the bottom, where it meets the screen edge.
    Rectangle {
        x: body.border.width
        y: parent.height - height
        width: parent.width - 2 * body.border.width
        height: Math.min(body.radius, parent.height / 2)
        color: Theme.palette.bg
    }
}
