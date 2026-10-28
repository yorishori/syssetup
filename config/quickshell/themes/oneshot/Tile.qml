import QtQuick
import qs.components as C
import qs.core

// A rounded cell; the current one glows faintly in the accent.
Item {
    id: root

    required property C.Tile control

    Box {
        anchors {
            fill: parent
            margins: 3
        }
        roundness: 12
        fill: root.control.current ? Qt.alpha(Theme.palette.accent, 0.18)
            : root.control.hovered ? Theme.palette.surface
            : "transparent"
    }
}
