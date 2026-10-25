import QtQuick
import qs.components as C
import qs.core

// A small enamelled badge riveted to the plate: its color, slightly domed,
// the text stamped on.
Item {
    id: root

    required property C.Tag control

    implicitWidth: label.implicitWidth + 14
    implicitHeight: label.implicitHeight + 4

    Rectangle {
        anchors.fill: parent
        radius: 3
        border.width: 1
        border.color: Qt.darker(root.control.fill, 1.8)
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.lighter(root.control.fill, 1.18) }
            GradientStop { position: 1; color: Qt.darker(root.control.fill, 1.15) }
        }

        Rectangle {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 1
            }
            height: 1
            color: Qt.alpha("white", 0.25)
        }
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
