import QtQuick
import qs.components as C
import qs.core

// Outlined key with a lamp; off is dim red and struck through.
Item {
    id: root

    required property C.Chip control

    implicitWidth: row.implicitWidth + 20
    implicitHeight: 26

    Chamfer {
        anchors.fill: parent
        cut: 5
        fill: root.control.hovered ? Theme.palette.surface : Theme.palette.bgAlt
        stroke: Theme.palette.border
    }
    Row {
        id: row

        anchors.centerIn: parent
        spacing: 8

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 6
            height: 6
            color: root.control.on ? Theme.palette.accent : Theme.palette.off
        }
        C.StyledText {
            text: root.control.text.toLowerCase()
            color: root.control.on ? Theme.palette.dim : Theme.palette.off
            font.pixelSize: Theme.font.size - 1
            font.strikeout: !root.control.on
        }
    }
}
