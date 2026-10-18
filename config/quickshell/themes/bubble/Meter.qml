import QtQuick
import qs.components as C
import qs.core

// Segmented: one rounded block per step.
Row {
    id: root

    required property C.Meter control

    spacing: 2

    Repeater {
        model: root.control.segments

        Rectangle {
            required property int index

            width: (root.width - (root.control.segments - 1) * 2) / root.control.segments
            height: root.height
            radius: Math.min(width, height) / 2
            color: index < root.control.lit ? root.control.color : Theme.palette.surface
            opacity: index < root.control.lit ? 1 : 0.6

            Behavior on color {
                ColorAnimation { duration: 90 }
            }
        }
    }
}
