import QtQuick
import qs.components as C
import qs.core

// A keycap with the glyph printed on it. It travels when pressed; lit, it
// latches in and the glyph is backlit.
Item {
    id: root

    required property C.IconButton control

    Key {
        id: key

        anchors.fill: parent
        down: root.control.pressed || root.control.lit
        hovered: root.control.hovered
        roundness: Math.min(Theme.values.shape?.radius ?? 0, height / 4)
    }

    Engraved {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: key.shift - key.travel / 2
        text: root.control.icon
        color: root.control.lit ? Theme.palette.accent : root.control.iconColor
        glow: root.control.lit
        rotation: root.control.iconRotation
        font.pixelSize: Math.round(root.control.size * 0.5)
    }
}
