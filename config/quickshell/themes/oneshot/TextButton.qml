import QtQuick
import qs.components as C
import qs.core

// A pill. Hover tints it with the accent, lit fills it; it squashes a little
// when pressed.
Item {
    id: root

    required property C.TextButton control

    implicitWidth: label.implicitWidth + 26
    implicitHeight: label.implicitHeight + 12
    opacity: control.enabled ? 1 : 0.4
    scale: control.pressed ? 0.88 : 1

    Behavior on scale {
        NumberAnimation { duration: 320; easing.type: Theme.motion.spring; easing.overshoot: Theme.motion.bounce }
    }

    Box {
        anchors.fill: parent
        roundness: height / 2
        fill: root.control.lit ? Theme.palette.accent
            : root.control.hovered ? Qt.alpha(Theme.palette.accent, 0.2)
            : Theme.palette.surface

        Behavior on fill {
            ColorAnimation { duration: 120 }
        }
    }

    C.StyledText {
        id: label

        anchors.centerIn: parent
        text: root.control.text
        caps: true
        tracking: 1.5
        font.pixelSize: Theme.font.size - 1
        font.bold: true
        color: root.control.lit ? Theme.palette.shadow : root.control.hovered ? Theme.palette.accent : Theme.palette.fg
    }
}
