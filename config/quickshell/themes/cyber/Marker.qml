import QtQuick
import qs.components as C

// A hard-edged bar.
Rectangle {
    required property C.Marker control

    color: control.color
}
