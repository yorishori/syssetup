import QtQuick
import qs.core

// Read-only segmented gauge (e.g. battery): `value` 0..1 lights segments.
Row {
    id: root

    property real value: 0
    property int segments: 5
    property color color: Config.colors.accent

    spacing: 1

    Repeater {
        model: root.segments

        Rectangle {
            required property int index

            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: 8
            color: index < Math.round(root.value * root.segments) ? root.color : Config.colors.surface
        }
    }
}
