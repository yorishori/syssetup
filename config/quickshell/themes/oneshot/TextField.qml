import QtQuick
import qs.components as C
import qs.core

// A recessed pill with the prompt in front and a thin breathing cursor; the
// outline lights up while typing, green with "saved" on flash().
Item {
    id: root

    required property C.TextField control
    readonly property bool focused: control.inputFocused

    // Where the input sits, and how it looks.
    readonly property real inputLeft: promptLabel.x + promptLabel.width + 8
    readonly property real inputRight: savedLabel.visible ? width - savedLabel.x + 10 : 16
    readonly property color textColor: Theme.palette.fg
    readonly property color selectionColor: Qt.alpha(Theme.palette.accent, 0.45)
    readonly property color selectedTextColor: Theme.palette.fg
    readonly property Component cursor: Component {
        Rectangle {
            width: 2
            radius: 1
            color: Theme.palette.accent
            visible: root.focused

            SequentialAnimation on opacity {
                running: root.focused
                loops: Animation.Infinite

                NumberAnimation { to: 1; duration: 80 }
                PauseAnimation { duration: 450 }
                NumberAnimation { to: 0; duration: 300; easing.type: Easing.InOutSine }
                PauseAnimation { duration: 150 }
            }
        }
    }

    implicitWidth: 200
    implicitHeight: control.inputHeight + 16

    Box {
        anchors.fill: parent
        roundness: height / 2
        fill: Theme.palette.bgAlt
        stroke: root.control.flashing ? Theme.palette.ok : root.focused ? Theme.palette.accent : "transparent"

        Behavior on stroke {
            ColorAnimation { duration: 150 }
        }
    }

    C.StyledText {
        id: promptLabel

        anchors {
            left: parent.left
            leftMargin: 16
            verticalCenter: parent.verticalCenter
        }
        text: root.control.prompt
        color: root.focused ? Theme.palette.accent : Theme.palette.muted
        font.bold: true
    }

    C.StyledText {
        anchors.verticalCenter: parent.verticalCenter
        x: root.inputLeft + (root.focused ? 4 : 0)
        width: root.width - root.inputLeft - root.inputRight
        text: root.control.placeholder
        color: Theme.palette.muted
        elide: Text.ElideRight
        visible: root.control.text === ""
    }

    C.StyledText {
        id: savedLabel

        anchors {
            right: parent.right
            rightMargin: 16
            verticalCenter: parent.verticalCenter
        }
        text: "\u{F012C} saved"
        color: Theme.palette.ok
        font.pixelSize: Theme.font.size - 2
        font.bold: true
        visible: root.control.flashing
    }
}
