import QtQuick
import qs.components as C
import qs.core

// A round key: clear until hovered, a filled accent bubble when lit. Squashes
// a little when pressed.
Item {
    id: root

    required property C.IconButton control

    scale: control.pressed ? 0.88 : 1

    Behavior on scale {
        NumberAnimation { duration: 200; easing.type: Theme.motion.spring }
    }

    Box {
        anchors.fill: parent
        roundness: height / 2
        fill: root.control.lit ? Theme.palette.accent : root.control.hovered ? Theme.palette.surface : "transparent"
    }

    C.StyledText {
        anchors.centerIn: parent
        text: root.control.icon
        color: root.control.lit ? Theme.palette.shadow : root.control.iconColor
        rotation: root.control.iconRotation
        font.pixelSize: Math.round(root.control.size * 0.55)
    }
}
