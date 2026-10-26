import QtQuick
import qs.components as C
import qs.core

// Four rising rounded bars.
Row {
    id: root

    required property C.SignalBars control

    spacing: 2

    Repeater {
        model: 4

        Rectangle {
            required property int index

            anchors.bottom: parent.bottom
            width: 3
            height: 4 + index * 3
            radius: 1.5
            color: root.control.strength > index * 25 ? root.control.color : Theme.palette.surface
        }
    }
}
