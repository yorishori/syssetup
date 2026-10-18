import QtQuick
import qs.components as C
import qs.core

// A thin slot down the right edge with a metal slider riding in it.
Item {
    id: root

    required property C.ScrollLamp control

    Well {
        x: root.width - width
        width: 5
        height: root.height
        roundness: 2.5
        opacity: 0.8
    }
    Rectangle {
        x: root.width - width
        y: root.control.position * root.height
        width: 5
        height: Math.max(10, root.control.ratio * root.height)
        radius: 2.5
        border.width: 1
        border.color: Theme.palette.shadow
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.lighter(Theme.palette.border, 1.5) }
            GradientStop { position: 1; color: Theme.palette.border }
        }
    }
}
