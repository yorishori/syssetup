import QtQuick
import qs.core

// Rounded box, the basic bubble shape; the outline is optional. `radius`
// defaults to the theme's roundness and never exceeds half the box.
Rectangle {
    property real roundness: Theme.values.shape?.radius ?? 0
    property color fill: Theme.palette.bg
    property color stroke: "transparent"
    property real strokeWidth: Theme.values.shape?.border ?? 0

    radius: Math.max(0, Math.min(roundness, width / 2, height / 2))
    color: fill
    border.color: stroke
    border.width: stroke.a > 0 ? strokeWidth : 0
}
