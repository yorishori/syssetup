import QtQuick
import qs.core

// Terminal line: recessed well, ">" prompt, blinking block cursor.
// For settings-style fields: submitOnEnter makes Enter leave the field (which
// ends editing, like clicking away), and flash() lights it green with "saved".
Item {
    id: root

    property alias text: input.text
    property alias echoMode: input.echoMode
    property string placeholder
    property string prompt: ">"
    readonly property bool inputFocused: input.activeFocus

    // When set, Left/Right don't move the text cursor but emit horizontal()
    // (e.g. to move through a grid of results).
    property bool captureHorizontal: false
    property bool submitOnEnter: false

    signal accepted(int modifiers)
    signal horizontal(int step)
    signal editingFinished  // Enter pressed or focus left

    function focusInput(): void {
        input.forceActiveFocus();
    }

    function flash(): void {
        saved.restart();
    }

    function enter(modifiers: int): void {
        root.accepted(modifiers);
        if (submitOnEnter)
            root.forceActiveFocus();  // keys now go to the panel (Escape closes it)
    }

    implicitWidth: 200
    implicitHeight: input.implicitHeight + 12

    Chamfer {
        anchors.fill: parent
        cut: 5
        fill: Config.colors.bgAlt
        stroke: saved.running ? Config.colors.ok : input.activeFocus ? Config.colors.accent : Config.colors.border
    }

    Timer {
        id: saved

        interval: 1200
    }

    StyledText {
        id: promptLabel

        anchors {
            left: parent.left
            leftMargin: 10
            verticalCenter: parent.verticalCenter
        }
        text: root.prompt
        color: input.activeFocus ? Config.colors.accent : Config.colors.muted
        glow: input.activeFocus
        font.bold: true
    }

    TextInput {
        id: input

        anchors {
            left: promptLabel.right
            right: savedLabel.visible ? savedLabel.left : parent.right
            leftMargin: 8
            rightMargin: 10
            verticalCenter: parent.verticalCenter
        }
        color: Config.colors.fg
        selectionColor: Config.colors.accent
        selectedTextColor: Config.colors.shadow
        font.family: Config.font.family
        font.pixelSize: Config.font.size
        clip: true
        Keys.onLeftPressed: event => {
            if (root.captureHorizontal)
                root.horizontal(-1);
            else
                event.accepted = false;
        }
        Keys.onRightPressed: event => {
            if (root.captureHorizontal)
                root.horizontal(1);
            else
                event.accepted = false;
        }
        onEditingFinished: root.editingFinished()
        Keys.onReturnPressed: event => root.enter(event.modifiers)
        Keys.onEnterPressed: event => root.enter(event.modifiers)

        cursorDelegate: Rectangle {
            width: 8
            color: Config.colors.accent
            visible: input.activeFocus

            SequentialAnimation on opacity {
                running: input.activeFocus
                loops: Animation.Infinite

                PropertyAction { value: 1 }
                PauseAnimation { duration: 530 }
                PropertyAction { value: 0 }
                PauseAnimation { duration: 530 }
            }
        }

        StyledText {
            anchors.fill: parent
            anchors.leftMargin: input.activeFocus ? 12 : 0  // clear of the block cursor
            text: root.placeholder
            color: Config.colors.muted
            visible: input.text === ""
        }
    }

    StyledText {
        id: savedLabel

        anchors {
            right: parent.right
            rightMargin: 10
            verticalCenter: parent.verticalCenter
        }
        text: "SAVED"
        color: Config.colors.ok
        font.pixelSize: Config.font.size - 3
        font.bold: true
        font.letterSpacing: 1.5
        visible: saved.running
    }
}
