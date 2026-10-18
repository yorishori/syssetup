import QtQuick
import qs.components as C
import qs.core

// Recessed cut-corner well; outlined only in its tone.
Item {
    id: root

    required property C.Entry control

    Chamfer {
        anchors.fill: parent
        cut: 5
        fill: root.control.hovered ? Theme.palette.surface : Theme.palette.bgAlt
        stroke: root.control.tone
    }
}
