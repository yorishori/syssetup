import QtQuick
import qs.components as C
import qs.core

// A smooth pill that fills up; a knob rides the end when it can be set.
Item {
    id: root

    required property C.Meter control
    readonly property real level: control.lit / Math.max(1, control.segments)
    readonly property real fillWidth: level > 0 ? Math.max(height, width * level) : 0

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.palette.surface
    }
    Rectangle {
        width: root.fillWidth
        height: parent.height
        radius: height / 2
        color: root.control.color

        Behavior on width {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }
    }
    Rectangle {
        readonly property real size: root.height + 6

        x: Math.max(0, Math.min(root.width - size, root.fillWidth - size))
        anchors.verticalCenter: parent.verticalCenter
        width: size
        height: size
        radius: size / 2
        color: Theme.palette.fg
        visible: root.control.interactive
    }
}
