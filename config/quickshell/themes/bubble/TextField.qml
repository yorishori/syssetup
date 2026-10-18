import QtQuick
import qs.components as C
import qs.core

// Rounded well with the prompt, a blinking block cursor; the outline goes
// accent while typing and green with "saved" on flash().
Item {
    id: root

    required property C.TextField control
    readonly property bool focused: control.inputFocused

    // Where the input sits, and how it looks.
    readonly property real inputLeft: promptLabel.x + promptLabel.width + 8
    readonly property real inputRight: savedLabel.visible ? width - savedLabel.x + 10 : 10
    readonly property color textColor: Theme.palette.fg
    readonly property color selectionColor: Theme.palette.accent
    readonly property color selectedTextColor: Theme.palette.shadow
    readonly property Component cursor: Component {
        Rectangle {
            width: 8
            color: Theme.palette.accent
            visible: root.focused

            SequentialAnimation on opacity {
                running: root.focused
                loops: Animation.Infinite

                PropertyAction { value: 1 }
                PauseAnimation { duration: 530 }
                PropertyAction { value: 0 }
                PauseAnimation { duration: 530 }
            }
        }
    }

    implicitWidth: 200
    implicitHeight: control.inputHeight + 12

    Box {
        anchors.fill: parent
        fill: Theme.palette.bgAlt
        stroke: root.control.flashing ? Theme.palette.ok : root.focused ? Theme.palette.accent : Theme.palette.border
    }

    C.StyledText {
        id: promptLabel

        anchors {
            left: parent.left
            leftMargin: 10
            verticalCenter: parent.verticalCenter
        }
        text: root.control.prompt
        color: root.focused ? Theme.palette.accent : Theme.palette.muted
        glow: root.focused
        font.bold: true
    }

    C.StyledText {
        anchors.verticalCenter: parent.verticalCenter
        x: root.inputLeft + (root.focused ? 12 : 0)  // clear of the block cursor
        width: root.width - root.inputLeft - root.inputRight
        text: root.control.placeholder
        color: Theme.palette.muted
        visible: root.control.text === ""
    }

    C.StyledText {
        id: savedLabel

        anchors {
            right: parent.right
            rightMargin: 10
            verticalCenter: parent.verticalCenter
        }
        text: "saved"
        caps: true
        color: Theme.palette.ok
        font.pixelSize: Theme.font.size - 3
        font.bold: true
        tracking: 1.5
        visible: root.control.flashing
    }
}
