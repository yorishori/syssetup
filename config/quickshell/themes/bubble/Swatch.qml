import QtQuick
import qs.components as C
import qs.core

// Rounded chip of the color, outlined when selected.
Item {
    id: root

    required property C.Swatch control

    implicitWidth: 20
    implicitHeight: 20

    Box {
        anchors.fill: parent
        fill: root.control.color
        stroke: root.control.selected ? Theme.palette.fg : "transparent"
        strokeWidth: 2
    }
    C.StyledText {
        anchors.centerIn: parent
        text: root.control.text
        color: Theme.palette.shadow
        font.pixelSize: Theme.font.size - 3
        font.bold: true
        visible: text !== ""
    }
}
