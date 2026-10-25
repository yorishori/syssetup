import QtQuick
import qs.components as C
import qs.core

// A record in a recessed slot of the plate; brighter glass on hover. With a
// tone, its bezel lights and a light pipe glows down its left edge.
Item {
    id: root

    required property C.Entry control
    readonly property bool toned: control.tone.a > 0

    Well {
        anchors.fill: parent
        roundness: (Theme.values.shape?.radius ?? 0) + 2
        fill: root.control.hovered ? Qt.lighter(Theme.palette.bgAlt, 1.6) : Theme.palette.bgAlt
        ring: root.toned ? Qt.alpha(root.control.tone, 0.6) : "transparent"
    }
    Rectangle {
        x: 2
        y: 8
        width: 2
        height: root.height - 16
        radius: 1
        color: root.control.tone
        visible: root.toned
    }
}
