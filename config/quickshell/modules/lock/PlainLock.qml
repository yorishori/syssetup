import QtQuick
import qs.services

// The lock's last resort, shown when the theme's lock screen can't load:
// plain Qt, no theme and no shared components, so nothing that breaks with
// them can lock you out. Enter tries the password, Escape clears it.
Rectangle {
    id: root

    color: "black"

    function refocus(): void {
        if (visible)
            input.forceActiveFocus();
    }

    // Keys only arrive once the lock window is active.
    readonly property bool windowActive: Window.active
    onWindowActiveChanged: refocus()
    onVisibleChanged: refocus()

    Connections {
        target: Session

        function onLockedChanged(): void {
            input.text = "";
        }
        function onFailuresChanged(): void {
            input.text = "";
        }
        // The field is off while checking, which takes its focus.
        function onAuthStateChanged(): void {
            root.refocus();
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 12

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            color: Session.authState === "failed" ? "salmon" : "white"
            font.pixelSize: 18
            text: Session.authState === "checking" ? "Checking…"
                : Session.authState === "failed" ? `Wrong password${Session.authMessage ? ": " + Session.authMessage : ""}`
                : "Locked. Type your password and press Enter."
        }

        Rectangle {
            width: 360
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
                echoMode: TextInput.Password
                clip: true
                enabled: Session.authState !== "checking"
                Keys.onReturnPressed: Session.unlockWith(text)
                Keys.onEnterPressed: Session.unlockWith(text)
                Keys.onEscapePressed: text = ""
            }
        }
    }
}
