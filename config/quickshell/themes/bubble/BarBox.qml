import QtQuick
import qs.core
import qs.modules.bar.widgets as W

// A pill inside the island, tinted in its tone.
Item {
    id: root

    required property W.BarBox control

    Box {
        anchors.fill: parent
        roundness: height / 2
        fill: root.control.tone.a > 0 ? Qt.alpha(root.control.tone, 0.16) : Theme.palette.surface
    }
}
