import QtQuick
import qs.components as C
import qs.core

// A soft rounded line.
Rectangle {
    required property C.Divider control

    implicitWidth: control.vertical ? 2 : 0
    implicitHeight: control.vertical ? 0 : 2
    radius: 1
    color: Theme.palette.surface
}
