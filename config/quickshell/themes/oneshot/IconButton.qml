import QtQuick
import qs.components as C
import qs.core

// A square key: clear until hovered, filled amber when lit; pressed, the
// glyph sinks a pixel.
Item {
    id: root

    required property C.IconButton control
    readonly property int px: Theme.get("pixel.scale") ?? 3

    Rectangle {
        anchors.fill: parent
        color: root.control.lit ? Theme.palette.accent : root.control.hovered ? Theme.palette.surface : "transparent"
    }
    Glyph {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.control.pressed ? root.px : 0
        text: root.control.icon
        color: root.control.lit ? Theme.palette.shadow : root.control.hovered ? Theme.palette.accent : root.control.iconColor
        rotation: root.control.iconRotation
        px: root.control.size >= 26 ? 3 : 2
        pixelSize: Math.round(root.control.size * 0.55)
    }
}
