import QtQuick
import qs.services

// The polkit prompt's last resort, shown when the theme's prompt can't load:
// plain Qt, no theme and no shared components. Enter authorizes, Escape
// cancels (the prompt holds the keyboard, so there must always be a way out).
Rectangle {
    id: root

    readonly property var flow: Polkit.flow

    function refocus(): void {
        if (visible)
            input.forceActiveFocus();
    }

    implicitWidth: 520
    implicitHeight: column.implicitHeight + 40
    color: "black"
    border.color: "white"
    border.width: 1

    function submit(): void {
        Polkit.submit(input.text);
        input.text = "";
    }

    // Keys only arrive once the prompt's window is active.
    readonly property bool windowActive: Window.active
    onWindowActiveChanged: refocus()
    onVisibleChanged: refocus()

    Connections {
        target: root.flow
        ignoreUnknownSignals: true

        function onAuthenticationFailed(): void {
            input.text = "";
            root.refocus();
        }
        function onIsResponseRequiredChanged(): void {
            root.refocus();
        }
    }

    Column {
        id: column

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 20
        }
        spacing: 12

        Text {
            width: parent.width
            color: "white"
            font.pixelSize: 16
            wrapMode: Text.Wrap
            textFormat: Text.PlainText
            text: root.flow?.message ?? ""
        }

        Text {
            width: parent.width
            color: root.flow?.failed ? "salmon" : "gray"
            font.pixelSize: 14
            wrapMode: Text.Wrap
            textFormat: Text.PlainText
            text: root.flow?.failed ? "Wrong password, try again."
                : `${root.flow?.inputPrompt || "Password:"} (Enter to authorize, Escape to cancel)`
        }

        Rectangle {
            width: parent.width
            height: 40
            color: "black"
            border.color: input.activeFocus ? "white" : "gray"
            border.width: 1

            TextInput {
                id: input

                anchors {
                    fill: parent
                    margins: 10
                }
                verticalAlignment: TextInput.AlignVCenter
                color: "white"
                font.pixelSize: 16
                echoMode: root.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                clip: true
                Keys.onReturnPressed: root.submit()
                Keys.onEnterPressed: root.submit()
                Keys.onEscapePressed: Polkit.cancel()
            }
        }
    }
}
