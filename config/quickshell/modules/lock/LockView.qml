import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.core
import qs.services

// What the lock screen shows (used by Lock.qml for each screen): clock and
// date; on the primary screen also the console: password prompt (focus always
// returns to it), passcode lamps when lock.passcode is set, and power keys
// (reboot and power off need a second press within 3 s).
Rectangle {
    id: root

    property bool primary: true
    readonly property int passcode: Config.lock.passcode
    property string armed: ""  // power key waiting for its second press

    // (This view only exists while the screen is locked.)
    function refocus(): void {
        if (primary)
            field.focusInput();
    }

    // Typing goes straight into the prompt, no click needed. The field's own
    // first focus can come too early: `primary` is only known once the lock
    // surface has its screen, and keys only arrive once the compositor makes
    // the lock window active. Focus again at both moments.
    readonly property bool windowActive: Window.active
    onPrimaryChanged: refocus()
    onWindowActiveChanged: refocus()

    function power(action: string): void {
        if (action === "sleep") {
            Session.suspend();
        } else if (armed === action) {
            armed = "";
            action === "reboot" ? Session.reboot() : Session.poweroff();
        } else {
            armed = action;
            disarm.restart();
        }
        refocus();
    }

    Timer {
        id: disarm
        interval: 3000
        onTriggered: root.armed = ""
    }

    // Clicking anywhere puts the focus back in the input.
    MouseArea {
        anchors.fill: parent
        onClicked: root.refocus()
    }

    color: Config.colors.bg

    Scanlines {
        anchors.fill: parent
    }

    ColumnLayout {
        id: panel

        anchors.centerIn: parent
        spacing: 18

        // Shake on a wrong password.
        transform: Translate {
            id: shake
        }
        SequentialAnimation {
            id: shakeAnim

            NumberAnimation { target: shake; property: "x"; to: -10; duration: 50 }
            NumberAnimation { target: shake; property: "x"; to: 10; duration: 70 }
            NumberAnimation { target: shake; property: "x"; to: -6; duration: 60 }
            NumberAnimation { target: shake; property: "x"; to: 0; duration: 80; easing.type: Easing.OutBack }
        }
        Connections {
            target: Session

            function onFailuresChanged(): void {
                if (Session.failures > 0) {
                    shakeAnim.restart();
                    field.text = "";
                }
                root.refocus();
            }
            function onLockedChanged(): void {
                field.text = "";
                root.armed = "";
                root.refocus();
            }
            function onAuthStateChanged(): void {
                root.refocus();
            }
        }

        // Clock
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(Time.now, "HH:mm")
            color: Config.colors.accent
            glow: true
            font.pixelSize: 96
            font.bold: true
        }
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDate(Time.now, "dddd d MMMM").toUpperCase()
            color: Config.colors.dim
            font.bold: true
            font.letterSpacing: 3
        }

        // Console (primary screen only)
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 24
            implicitWidth: 420
            implicitHeight: box.implicitHeight + 36
            visible: root.primary

            Card {
                anchors.fill: parent
            }

            ColumnLayout {
                id: box

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 18
                }
                spacing: 12

                SectionTitle {
                    text: "LOCKED"
                    code: Session.hostname.toUpperCase()
                }
                RowLayout {
                    spacing: 10

                    Lamp {
                        on: true
                        litColor: Session.authState === "failed" ? Config.colors.warn : Config.colors.accent
                    }
                    StyledText {
                        text: Quickshell.env("USER") ?? ""
                        font.bold: true
                    }
                }
                TextField {
                    id: field

                    Layout.fillWidth: true
                    prompt: root.passcode > 0 ? "code>" : "pass>"
                    placeholder: root.passcode > 0 ? "passcode" : "password"
                    echoMode: TextInput.Password
                    onAccepted: Session.unlockWith(text)
                    // Passcode mode: check as soon as enough is typed.
                    onTextChanged: {
                        if (root.passcode > 0 && text.length === root.passcode)
                            Session.unlockWith(text);
                    }
                    // Never let the focus wander off.
                    onInputFocusedChanged: {
                        if (!inputFocused)
                            Qt.callLater(root.refocus);
                    }

                    Component.onCompleted: root.refocus()
                }
                // Passcode lamps: one per character, lit as you type.
                Row {
                    spacing: 6
                    visible: root.passcode > 0

                    Repeater {
                        model: root.passcode

                        Lamp {
                            required property int index

                            implicitWidth: 12
                            implicitHeight: 12
                            on: index < field.text.length
                            litColor: Session.authState === "failed" ? Config.colors.warn : Config.colors.accent
                        }
                    }
                }
                StyledText {
                    text: Session.authState === "checking" ? "AUTHENTICATING…"
                        : Session.authState === "failed" ? `ACCESS DENIED · ${String(Session.failures).padStart(2, "0")}`
                        : root.passcode > 0 ? "TYPE YOUR PASSCODE" : "ENTER TO UNLOCK"
                    color: Session.authState === "failed" ? Config.colors.warn : Config.colors.muted
                    font.pixelSize: Config.font.size - 2
                    font.bold: true
                    font.letterSpacing: 1.5
                }
                StyledText {
                    Layout.fillWidth: true
                    text: Session.authMessage
                    color: Config.colors.muted
                    font.pixelSize: Config.font.size - 3
                    wrapMode: Text.Wrap
                    visible: text !== ""
                }

                // Power keys
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    implicitHeight: 1
                    color: Config.colors.border
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    TextButton {
                        text: root.armed === "reboot" ? "confirm?" : "\u{F0709}  reboot"
                        lit: root.armed === "reboot"
                        onClicked: root.power("reboot")
                    }
                    TextButton {
                        text: "\u{F0904}  sleep"
                        onClicked: root.power("sleep")
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    TextButton {
                        text: root.armed === "poweroff" ? "confirm?" : "\u{F0425}  power off"
                        lit: root.armed === "poweroff"
                        onClicked: root.power("poweroff")
                    }
                }
            }
        }
    }
}
