import QtQuick
import qs.components as C
import qs.core

// A hairline.
Rectangle {
    required property C.Divider control

    implicitWidth: control.vertical ? 1 : 0
    implicitHeight: control.vertical ? 0 : 1
    color: Theme.palette.border
}
