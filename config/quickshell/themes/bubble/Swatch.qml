import QtQuick
import qs.components as C
import qs.core

// A dot of the color (a pill when wider); the selected one gets a ring.
Item {
    id: root

    required property C.Swatch control

    implicitWidth: 20
    implicitHeight: 20

    Rectangle {
        anchors.centerIn: parent
        width: parent.width - (root.control.selected ? 6 : 0)
        height: parent.height - (root.control.selected ? 6 : 0)
        radius: height / 2
        color: root.control.color
        scale: root.control.hovered && !root.control.selected ? 1.18 : 1

        Behavior on scale {
            NumberAnimation { duration: 260; easing.type: Theme.motion.spring; easing.overshoot: Theme.motion.bounce }
        }
    }
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: "transparent"
        border.color: Theme.palette.fg
        border.width: 2
        visible: root.control.selected
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
