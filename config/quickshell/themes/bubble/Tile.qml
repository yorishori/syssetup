import QtQuick
import qs.components as C
import qs.core

// Rounded cell, lit outline on the current one.
Item {
    id: root

    required property C.Tile control

    Box {
        anchors {
            fill: parent
            margins: 2
        }
        fill: root.control.current ? Theme.palette.surface : root.control.hovered ? Theme.palette.bgAlt : "transparent"
        stroke: root.control.current ? Theme.palette.accent : "transparent"
    }
}
