import QtQuick
import qs.components as C
import qs.core

// A row of thin bars, lit up to the value.
Row {
    id: root

    required property C.Gauge control

    spacing: 1

    Repeater {
        model: root.control.segments

        Rectangle {
            required property int index

            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: 8
            color: index < Math.round(root.control.value * root.control.segments) ? root.control.color : Theme.palette.surface
        }
    }
}
