import QtQuick
import qs.components as C
import qs.core

// A sunken well, framed a pixel thick, the prompt in small capitals in front
// and a blinking block caret; the frame lights amber while typing, mint
// with "saved" on flash().
Item {
    id: root

    required property C.TextField control
    readonly property bool focused: control.inputFocused
    readonly property int px: Theme.get("pixel.scale") ?? 3

    // Where the input sits, and how it looks.
    readonly property real inputLeft: promptLabel.x + promptLabel.width + 10
    readonly property real inputRight: savedLabel.visible ? width - savedLabel.x + 10 : 12
    readonly property color textColor: Theme.palette.fg
    readonly property color selectionColor: Qt.alpha(Theme.palette.accent, 0.45)
    readonly property color selectedTextColor: Theme.palette.fg
    readonly property Component cursor: Component {
        Rectangle {
            width: root.px
            color: Theme.palette.accent
            visible: root.focused && blink.on

            Timer {
                id: blink

                property bool on: true

                interval: 500
                repeat: true
                running: root.focused
                onTriggered: on = !on
            }
        }
    }

    implicitWidth: 200
    implicitHeight: control.inputHeight + 18

    Rectangle {
        anchors.fill: parent
        color: root.control.flashing ? Theme.palette.ok : root.focused ? Theme.palette.accent : "#4a4068"

        Rectangle {
            anchors.fill: parent
            anchors.margins: root.px
            color: Theme.palette.bgAlt
        }
    }

    C.StyledText {
        id: promptLabel

        anchors {
            left: parent.left
            leftMargin: 12
            verticalCenter: parent.verticalCenter
        }
        text: root.control.prompt
        color: root.focused ? Theme.palette.accent : Theme.palette.dim
        font.family: Theme.get("font.labels") ?? Theme.font.family
        font.pixelSize: Theme.font.size - 2
        caps: true
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
        text: "saved"
        color: Theme.palette.ok
        font.family: Theme.get("font.labels") ?? Theme.font.family
        font.pixelSize: Theme.font.size - 2
        caps: true
        visible: root.control.flashing
    }
}
