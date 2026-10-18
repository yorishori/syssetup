import QtQuick
import qs.components as C
import qs.core

// Thin accent bar on the right edge.
Item {
    id: root

    required property C.ScrollLamp control

    Rectangle {
        x: root.width - width
        y: root.control.position * root.height
        width: 2
        height: root.control.ratio * root.height
        color: Theme.palette.accent
    }
}
