import QtQuick
import qs.components as C
import qs.core

// Small round lamp.
Rectangle {
    id: root

    required property C.Lamp control

    implicitWidth: 6
    implicitHeight: 6
    color: control.on ? control.litColor : Theme.palette.surface

    SequentialAnimation on opacity {
        running: root.control.pulse
        loops: Animation.Infinite
        alwaysRunToEnd: true

        NumberAnimation { to: 0.25; duration: 700; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
    }
}
