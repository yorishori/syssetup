import QtQuick
import qs.components as C
import qs.core

// A framed plum key. Hover lights the frame and label amber, lit fills it
// amber; pressed, it sinks a pixel.
Item {
    id: root

    required property C.TextButton control
    readonly property int px: Theme.get("pixel.scale") ?? 3

    implicitWidth: label.implicitWidth + 24
    implicitHeight: label.implicitHeight + 12
    opacity: control.enabled ? 1 : 0.4

    Item {
        width: parent.width
        height: parent.height
        y: root.control.pressed ? root.px : 0

        Rectangle {
            anchors.fill: parent
            color: root.control.lit || root.control.hovered ? Theme.palette.accent : "#4a4068"

            Rectangle {
                anchors.fill: parent
                anchors.margins: root.px
                color: root.control.lit ? Theme.palette.accent : Theme.palette.surface
            }
        }
        C.StyledText {
            id: label

            anchors.centerIn: parent
            text: root.control.text
            color: root.control.lit ? Theme.palette.shadow : root.control.hovered ? Theme.palette.accent : Theme.palette.fg
        }
    }
}
