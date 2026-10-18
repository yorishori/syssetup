import QtQuick
import qs.components as C
import qs.core

// A tiny pill, filled up to the value.
Item {
    id: root

    required property C.Gauge control

    implicitWidth: 18
    implicitHeight: 8

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.palette.surface
    }
    Rectangle {
        width: Math.max(height, parent.width * Math.max(0, Math.min(1, root.control.value)))
        height: parent.height
        radius: height / 2
        color: root.control.color
        visible: root.control.value > 0
    }
}
