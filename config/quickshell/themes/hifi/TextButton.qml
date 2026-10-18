import QtQuick
import qs.components as C
import qs.core

// A keycap with its label silk-screened on. It travels when pressed; lit, it
// latches in and the label is backlit.
Item {
    id: root

    required property C.TextButton control

    implicitWidth: label.implicitWidth + 26
    implicitHeight: label.implicitHeight + 14
    opacity: control.enabled ? 1 : 0.4

    Key {
        id: key

        anchors.fill: parent
        down: root.control.pressed || root.control.lit
        hovered: root.control.hovered && root.control.enabled
    }

    Engraved {
        id: label

        anchors.centerIn: parent
        anchors.verticalCenterOffset: key.shift - key.travel / 2
        text: root.control.text
        caps: true
        tracking: 1.5
        glow: root.control.lit
        font.pixelSize: Theme.font.size - 1
        font.bold: true
        color: root.control.lit ? Theme.palette.accent : root.control.hovered ? Theme.palette.fg : Theme.palette.dim
    }
}
