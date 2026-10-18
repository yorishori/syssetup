import QtQuick
import qs.components as C
import qs.core

// Small filled pill.
Item {
    id: root

    required property C.Tag control

    implicitWidth: label.implicitWidth + 14
    implicitHeight: label.implicitHeight + 4

    Box {
        anchors.fill: parent
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
        tracking: 1.5
    }
}
