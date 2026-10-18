import QtQuick
import qs.components as C
import qs.core

// Rounded key; lights up (accent fill) on hover, sinks a pixel when
// pressed.
Item {
    id: root

    required property C.TextButton control
    readonly property bool on: control.lit || control.hovered

    implicitWidth: label.implicitWidth + 22
    implicitHeight: label.implicitHeight + 10
    opacity: control.enabled ? 1 : 0.4

    Box {
        anchors.fill: parent
        transform: Translate { y: root.control.pressed ? 1 : 0 }
        fill: root.on ? Theme.palette.accent : Theme.palette.bgAlt
        stroke: root.on ? Theme.palette.accent : Theme.palette.border
    }

    C.StyledText {
        id: label

        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.control.pressed ? 1 : 0
        text: root.control.text
        caps: true
        tracking: 1.5
        font.pixelSize: Theme.font.size - 2
        font.bold: true
        color: root.on ? Theme.palette.shadow : Theme.palette.fg
    }
}
