import QtQuick
import qs.components as C
import qs.core

// Tab strip; a bar slides under the current tab.
Item {
    id: root

    required property C.Tabs control

    implicitHeight: 26

    Repeater {
        model: root.control.tabs

        Item {
            id: tab

            required property int index
            required property string modelData
            readonly property bool active: root.control.current === index

            x: index * root.control.tabWidth
            width: root.control.tabWidth
            height: root.height - 3

            C.StyledText {
                anchors.centerIn: parent
                text: tab.modelData
                caps: true
                color: tab.active ? Theme.palette.accent : root.control.hovered === tab.index ? Theme.palette.fg : Theme.palette.dim
                glow: tab.active
                font.pixelSize: Theme.font.size - 2
                font.bold: true
                tracking: 1.5
            }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.palette.border
    }

    Rectangle {
        x: root.control.current * root.control.tabWidth + 12
        anchors.bottom: parent.bottom
        width: root.control.tabWidth - 24
        height: 2
        radius: 1
        color: Theme.palette.accent

        Behavior on x {
            NumberAnimation { duration: 240; easing.type: Easing.OutBack }
        }
    }
}
