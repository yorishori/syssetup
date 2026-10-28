import QtQuick
import qs.core

// The basic block. Pixels are square, so it never rounds (`roundness` is
// taken and ignored, for skins written for rounder themes); the outline is
// one art pixel. `raised` edges it in the cream frame unless it has a
// stroke of its own.
Rectangle {
    id: root

    property real roundness: 0
    property color fill: Theme.palette.bg
    property color stroke: "transparent"
    property real strokeWidth: Theme.get("pixel.scale") ?? 3
    property bool raised: false

    radius: 0
    color: fill
    border.color: stroke.a > 0 ? stroke : Theme.palette.border
    border.width: stroke.a > 0 || raised ? strokeWidth : 0
}
