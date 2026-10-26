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
    C.StyledText {
        id: label

        anchors.centerIn: parent
        text: root.control.text
        caps: true
        color: root.control.textColor
        font.family: Theme.get("font.labels") ?? Theme.font.family
        font.pixelSize: root.control.size
    }
}
