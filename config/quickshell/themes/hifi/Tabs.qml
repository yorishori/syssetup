import QtQuick
import qs.components as C
import qs.core

// An input selector: a row of latching keys in a recessed bay. Pressing one
// latches it in, lights its LED and backlights its label, and releases the
// rest.
Item {
    id: root

    required property C.Tabs control

    implicitHeight: 32

    Well {
        anchors.fill: parent
    }

    Repeater {
        model: root.control.tabs

        Item {
            required property int index
            required property string modelData
            readonly property bool active: root.control.current === index

            x: index * root.control.tabWidth + 3
            y: 3
            width: root.control.tabWidth - 6
            height: root.height - 5

            Key {
                id: key

                anchors.fill: parent
                down: parent.active
                hovered: root.control.hovered === parent.index
            }
            Led {
                x: 8
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: key.shift - key.travel / 2
                size: 6
                on: parent.active
            }
            Engraved {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: key.shift - key.travel / 2
                width: parent.width - 32
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: parent.modelData
                caps: true
                tracking: 1
                glow: parent.active
                color: parent.active ? Theme.palette.accent : root.control.hovered === parent.index ? Theme.palette.fg : Theme.palette.dim
                font.pixelSize: Theme.font.size - 1
                font.bold: true
            }
        }
    }
}
