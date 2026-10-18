import QtQuick
import qs.core
import qs.modules.bar.widgets as W

// Rounded well, outlined in its tone.
Item {
    id: root

    required property W.BarBox control

    Box {
        anchors.fill: parent
        fill: Theme.palette.bgAlt
        stroke: root.control.tone.a > 0 ? root.control.tone : Theme.palette.border
    }
}
