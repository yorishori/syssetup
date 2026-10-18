import QtQuick
import qs.components as C
import qs.core

// Rounded well; outlined only in its tone.
Item {
    id: root

    required property C.Entry control

    Box {
        anchors.fill: parent
        fill: root.control.hovered ? Theme.palette.surface : Theme.palette.bgAlt
        stroke: root.control.tone
    }
}
