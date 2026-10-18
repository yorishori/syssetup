import QtQuick
import qs.components as C

// A rounded bar.
Rectangle {
    required property C.Marker control

    radius: Math.min(width, height) / 2
    color: control.color
}
