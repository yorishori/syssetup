import QtQuick
import qs.components as C
import qs.core

// A glass display recessed into the plate: the prompt lights up on it while
// you type, behind a glowing cursor, and its bezel lights in the display
// color; in green, with "saved", on flash().
Item {
    id: root

    required property C.TextField control
    readonly property bool focused: control.inputFocused

    // Where the input sits, and how it looks.
    readonly property real inputLeft: promptLabel.x + promptLabel.width + 8
    readonly property real inputRight: savedLabel.visible ? width - savedLabel.x + 10 : 14
    readonly property color textColor: Theme.palette.fg
    readonly property color selectionColor: Qt.alpha(Theme.palette.accent, 0.35)
    readonly property color selectedTextColor: Theme.palette.fg
    readonly property Component cursor: Component {
        Rectangle {
            width: 2
            color: Theme.palette.accent
            visible: root.focused

            // A display blinks hard: on, off.
            SequentialAnimation on opacity {
                running: root.focused
                loops: Animation.Infinite

                PropertyAction { value: 1 }
                PauseAnimation { duration: 530 }
                PropertyAction { value: 0 }
                PauseAnimation { duration: 400 }
            }
        }
    }

    implicitWidth: 200
    implicitHeight: control.inputHeight + 16

    Well {
        id: glass

        anchors.fill: parent
        fill: root.focused ? Qt.tint(Theme.palette.bgAlt, Qt.alpha(Theme.palette.accent, 0.03)) : Theme.palette.bgAlt
        ring: root.control.flashing ? Theme.palette.ok : root.focused ? Qt.alpha(Theme.palette.accent, 0.55) : "transparent"
    }

    C.StyledText {
        id: promptLabel

        anchors {
            left: parent.left
            leftMargin: 12
            verticalCenter: parent.verticalCenter
        }
        text: root.control.prompt
        color: root.focused ? Theme.palette.accent : Theme.palette.muted
        glow: root.focused
        font.bold: true
    }

    C.StyledText {
        anchors.verticalCenter: parent.verticalCenter
        x: root.inputLeft
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
            rightMargin: 12
            verticalCenter: parent.verticalCenter
        }
        text: "\u{F012C} saved"
        caps: true
        color: Theme.palette.ok
        glow: true
        font.pixelSize: Theme.font.size - 2
        font.bold: true
        visible: root.control.flashing
    }

    Gloss {
        anchors {
            fill: parent
            margins: 1
        }
        roundness: glass.r
    }
}
