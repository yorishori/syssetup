import QtQuick
import qs.components as C
import qs.core

// Console fill, hairline outline (in the tone, when there is one), cut
// corners, faint scanlines.
Item {
    id: root

    required property C.Card control

    Chamfer {
        anchors.fill: parent
        fill: Theme.palette.bg
        stroke: root.control.tone.a > 0 ? root.control.tone : Theme.palette.border
    }

    Scanlines {
        anchors {
            fill: parent
            topMargin: Theme.values.shape?.cut ?? 0
            bottomMargin: Theme.values.shape?.cut ?? 0
        }
    }
}
