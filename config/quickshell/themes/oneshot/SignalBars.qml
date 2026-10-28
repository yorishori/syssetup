import QtQuick
import qs.components as C
import qs.core

// Four rising pixel blocks, lit by strength.
Row {
    id: root

    required property C.SignalBars control

    spacing: 2

    Repeater {
        model: 4

        Rectangle {
            required property int index

            anchors.bottom: parent.bottom
            width: 4
            height: 4 + index * 4
            color: root.control.strength > index * 25 ? root.control.color : Theme.palette.surface
        }
    }
}
