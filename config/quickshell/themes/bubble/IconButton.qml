import QtQuick
import qs.components as C
import qs.core

// Glyph key. Transparent until hovered; lit is a filled accent bubble.
// Squashes a little when pressed.
Item {
    id: root

    required property C.IconButton control

    scale: control.pressed ? 0.9 : 1

    Behavior on scale {
        NumberAnimation { duration: 180; easing.type: Easing.OutBack }
    }

    Box {
        anchors.fill: parent
        fill: root.control.lit ? Theme.palette.accent : root.control.hovered ? Theme.palette.surface : "transparent"
    }

    C.StyledText {
        anchors.centerIn: parent
        text: root.control.icon
        color: root.control.lit ? Theme.palette.shadow : root.control.iconColor
        rotation: root.control.iconRotation
        font.bold: true
        font.pixelSize: Math.round(root.control.size * 0.55)
    }
}
