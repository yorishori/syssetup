import QtQuick
import qs.components as C
import qs.core

// A small filled block with a label in small capitals.
Item {
    id: root

    required property C.Tag control

    implicitWidth: label.implicitWidth + 12
    implicitHeight: label.implicitHeight + 4

    Rectangle {
        anchors.fill: parent
        color: root.control.fill
    }
    Glyph {
        id: label

        anchors.centerIn: parent
        text: root.control.text
        color: root.control.textColor
        pixelSize: root.control.size
        px: 2
    }
}
