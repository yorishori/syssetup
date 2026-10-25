import QtQuick
import qs.components as C
import qs.core

// A groove machined into the plate: a dark cut with light on its far lip.
Item {
    id: root

    required property C.Divider control

    implicitWidth: control.vertical ? 2 : 0
    implicitHeight: control.vertical ? 0 : 2

    Rectangle {
        width: root.control.vertical ? 1 : parent.width
        height: root.control.vertical ? parent.height : 1
        color: Qt.alpha(Theme.palette.shadow, 0.8)
    }
    Rectangle {
        x: root.control.vertical ? 1 : 0
        y: root.control.vertical ? 0 : 1
        width: root.control.vertical ? 1 : parent.width
        height: root.control.vertical ? parent.height : 1
        color: Qt.alpha("white", 0.08)
    }
}
