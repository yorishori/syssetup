import QtQuick
import qs.core
import qs.modules.bar.widgets as W

// Like a recessed panel on a console: cut-corner well, hairline in its tone.
Item {
    id: root

    required property W.BarBox control

    Chamfer {
        anchors.fill: parent
        cut: 5
        fill: Theme.palette.bgAlt
        stroke: root.control.tone.a > 0 ? root.control.tone : Theme.palette.border
    }
}
