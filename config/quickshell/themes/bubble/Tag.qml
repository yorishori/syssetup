import QtQuick
import qs.components as C
import qs.core

// Small filled pill.
Item {
    id: root

    required property C.Tag control

    implicitWidth: label.implicitWidth + 16
    implicitHeight: label.implicitHeight + 4

    Box {
        anchors.fill: parent
        roundness: height / 2
        fill: root.control.fill
    }
    C.StyledText {
        id: label

        anchors.centerIn: parent
        text: root.control.text
        caps: true
        color: root.control.textColor
        font.pixelSize: root.control.size
        font.bold: true
    }
}
