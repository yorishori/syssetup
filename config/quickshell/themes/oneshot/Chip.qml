import QtQuick
import qs.components as C
import qs.core

// A block with a square dot: tinted in the accent when on, dim red and struck
// through when off.
Item {
    id: root

    required property C.Chip control

    implicitWidth: row.implicitWidth + 22
    implicitHeight: 26

    Box {
        anchors.fill: parent
        roundness: height / 2
        fill: root.control.hovered ? Theme.palette.surface
            : root.control.on ? Qt.alpha(Theme.palette.accent, 0.14)
            : Theme.palette.bgAlt
    }
    Row {
        id: row

        anchors.centerIn: parent
        spacing: 7

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 6
            height: 6
            color: root.control.on ? Theme.palette.accent : Theme.palette.off
        }
        C.StyledText {
            text: root.control.text.toLowerCase()
            color: root.control.on ? Theme.palette.fg : Theme.palette.off
            font.pixelSize: Theme.font.size - 1
            font.strikeout: !root.control.on
        }
    }
}
