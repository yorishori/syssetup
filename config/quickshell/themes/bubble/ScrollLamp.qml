import QtQuick
import qs.components as C
import qs.core

// A thin pill on the right edge.
Item {
    id: root

    required property C.ScrollLamp control

    Rectangle {
        x: root.width - width
        y: root.control.position * root.height
        width: 3
        height: root.control.ratio * root.height
        radius: 1.5
        color: Theme.palette.accent
        opacity: 0.7
    }
}
