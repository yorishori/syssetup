import QtQuick
import QtQuick.Effects
import qs.core

// Rounded box, the basic bubble shape. `roundness` defaults to the theme's
// and never exceeds half the box (so a large one makes a pill); the outline
// is optional. `raised` floats it on a soft shadow, edged with the theme's
// outline unless it has a stroke of its own.
Rectangle {
    id: root

    property real roundness: Theme.values.shape?.radius ?? 0
    property color fill: Theme.palette.bg
    property color stroke: "transparent"
    property real strokeWidth: Theme.values.shape?.border ?? 0
    property bool raised: false
    readonly property real shadow: Theme.values.effects?.shadow ?? 0

    radius: Math.max(0, Math.min(roundness, width / 2, height / 2))
    color: fill
    readonly property real outline: Theme.values.shape?.outline ?? 0

    border.color: stroke.a > 0 ? stroke : Theme.palette.border
    border.width: stroke.a > 0 ? strokeWidth : raised ? outline : 0

    RectangularShadow {
        z: -1
        anchors.fill: parent
        visible: root.raised && root.shadow > 0
        radius: root.radius
        offset.y: 4
        blur: 20
        color: Qt.alpha(Theme.palette.shadow, root.shadow)
    }
}
