import QtQuick
import qs.components as C
import qs.core

// A rounded recessed card; outlined in its tone.
Item {
    id: root

    required property C.Entry control

    Box {
        anchors.fill: parent
        roundness: 12
        fill: root.control.hovered ? Theme.palette.surface : Theme.palette.bgAlt
        stroke: root.control.tone
    }
}
