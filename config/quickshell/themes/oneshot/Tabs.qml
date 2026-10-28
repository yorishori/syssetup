import QtQuick
import qs.components as C
import qs.core

// A segmented pill; a bubble slides under the current tab.
Item {
    id: root

    required property C.Tabs control

    implicitHeight: 30

    Box {
        anchors.fill: parent
        roundness: height / 2
        fill: Theme.palette.bgAlt
    }
    Box {
        x: root.control.current * root.control.tabWidth + 3
        y: 3
        width: root.control.tabWidth - 6
        height: root.height - 6
        roundness: height / 2
        fill: Theme.palette.surface

        Behavior on x {
            NumberAnimation { duration: 380; easing.type: Theme.motion.spring; easing.overshoot: Theme.motion.bounce }
        }
    }

    Repeater {
        model: root.control.tabs

        C.StyledText {
            required property int index
            required property string modelData
            readonly property bool active: root.control.current === index

            x: index * root.control.tabWidth
            width: root.control.tabWidth
            height: root.height
            horizontalAlignment: Text.AlignHCenter
            text: modelData
            caps: true
            color: active ? Theme.palette.accent : root.control.hovered === index ? Theme.palette.fg : Theme.palette.dim
            font.pixelSize: Theme.font.size - 1
            font.bold: active
        }
    }
}
