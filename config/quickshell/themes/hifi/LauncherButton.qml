import QtQuick
import qs.core
import qs.modules.bar.widgets as W

// The RUN key, as on a console: a big momentary keycap. It springs back
// after the press; its legend stays backlit while the launcher is open.
Item {
    id: root

    required property W.LauncherButton control

    implicitWidth: 52
    implicitHeight: 34

    Key {
        id: key

        anchors.fill: parent
        down: root.control.pressed
        hovered: root.control.hovered
        glowColor: root.control.active ? Theme.palette.accent : "transparent"
    }
    Engraved {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: key.shift - key.travel / 2
        text: "RUN"
        tracking: 2
        glow: root.control.active
        color: root.control.active ? Theme.palette.accent : root.control.hovered ? Theme.palette.fg : Theme.palette.dim
        font.pixelSize: Theme.font.size - 1
        font.bold: true
    }
}
