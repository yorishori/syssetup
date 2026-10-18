import QtQuick
import qs.components as C
import qs.core

// Cut-corner cell, lit outline on the current one.
Item {
    id: root

    required property C.Tile control

    Chamfer {
        anchors {
            fill: parent
            margins: 2
        }
        cut: 5
        fill: root.control.current ? Theme.palette.surface : root.control.hovered ? Theme.palette.bgAlt : "transparent"
        stroke: root.control.current ? Theme.palette.accent : "transparent"
    }
}
