import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core
import qs.modules.lock as M

// The clock and date; on the primary screen the console with the password
// prompt, the passcode lamps and the power keys. A wrong password shakes it.
Item {
    id: root

    required property M.LockView control

    Connections {
        target: root.control

        function onFailed(): void {
            shakeAnim.restart();
            field.text = "";
        }
        function onReset(): void {
            field.text = "";
        }
        function onRefocusRequested(): void {
            field.focusInput();
        }
    }

    ScreenFill {
        anchors.fill: parent
    }

    // Clicking anywhere puts the focus back in the input.
    MouseArea {
        anchors.fill: parent
        onClicked: root.control.refocus()
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
            NumberAnimation { target: shake; property: "x"; to: 0; duration: 80; easing.type: Theme.motion.spring; easing.overshoot: Theme.motion.bounce }
        }

        // Clock
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(root.control.now, "HH:mm")
            color: Theme.palette.accent
            glow: true
            font.pixelSize: 96
            font.bold: true
        }
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDate(root.control.now, "dddd d MMMM")
            caps: true
            color: Theme.palette.dim
            font.bold: true
            tracking: 3
        }

        // Console (primary screen only)
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 24
            implicitWidth: 420
            implicitHeight: box.implicitHeight + 36
            visible: root.control.primary

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
                    text: "Locked"
                    code: root.control.hostname
                }
                RowLayout {
                    spacing: 10

                    Lamp {
                        on: true
                        litColor: root.control.authState === "failed" ? Theme.palette.warn : Theme.palette.accent
                    }
                    StyledText {
                        text: root.control.user
                        font.bold: true
                    }
                }
                TextField {
                    id: field

                    Layout.fillWidth: true
                    prompt: root.control.passcode > 0 ? "code>" : "pass>"
                    placeholder: root.control.passcode > 0 ? "passcode" : "password"
                    echoMode: TextInput.Password
                    onAccepted: root.control.unlock(text)
                    // Passcode mode: check as soon as enough is typed.
                    onTextChanged: {
                        if (root.control.passcode > 0 && text.length === root.control.passcode)
                            root.control.unlock(text);
                    }
                    // Never let the focus wander off.
                    onInputFocusedChanged: {
                        if (!inputFocused)
                            Qt.callLater(root.control.refocus);
                    }

                    Component.onCompleted: root.control.refocus()
                }
                // Passcode lamps: one per character, lit as you type.
                Row {
                    spacing: 6
                    visible: root.control.passcode > 0

                    Repeater {
                        model: root.control.passcode

                        Lamp {
                            required property int index

                            implicitWidth: 12
                            implicitHeight: 12
                            on: index < field.text.length
                            litColor: root.control.authState === "failed" ? Theme.palette.warn : Theme.palette.accent
                        }
                    }
                }
                StyledText {
                    text: root.control.authState === "checking" ? "authenticating…"
                        : root.control.authState === "failed" ? `access denied · ${String(root.control.failures).padStart(2, "0")}`
                        : root.control.passcode > 0 ? "type your passcode" : "enter to unlock"
                    caps: true
                    color: root.control.authState === "failed" ? Theme.palette.warn : Theme.palette.muted
                    font.pixelSize: Theme.font.size - 2
                    font.bold: true
                    tracking: 1.5
                }
                StyledText {
                    Layout.fillWidth: true
                    text: root.control.authMessage
                    color: Theme.palette.muted
                    font.pixelSize: Theme.font.size - 3
                    wrapMode: Text.Wrap
                    visible: text !== ""
                }

                // Power keys
                Divider {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    TextButton {
                        text: root.control.armed === "reboot" ? "confirm?" : "\u{F0709}  reboot"
                        lit: root.control.armed === "reboot"
                        onClicked: root.control.power("reboot")
                    }
                    TextButton {
                        text: "\u{F0904}  sleep"
                        onClicked: root.control.power("sleep")
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    TextButton {
                        text: root.control.armed === "poweroff" ? "confirm?" : "\u{F0425}  power off"
                        lit: root.control.armed === "poweroff"
                        onClicked: root.control.power("poweroff")
                    }
                }
            }
        }
    }
}
