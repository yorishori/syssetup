import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core
import qs.modules.lock as M

// The forest, a little dimmer, with the clock in lantern amber; on the
// primary screen an RPG window with the password prompt, the passcode
// lamps and the power keys, and the cat asleep on top of it. It wakes when
// you start typing and stays up while a password fails, then dozes off
// again. Locking and unlocking fade the scene in four steps; a wrong
// password jitters the window in pixel hops.
Item {
    id: root

    required property M.LockView control

    readonly property int px: Theme.get("pixel.scale") ?? 3
    // The fade, 0 (the desktop) to 4 (locked): up while closing, down
    // while opening, simply there once locked.
    property int step: control.phase === "closing" ? 0 : 4
    readonly property int target: control.phase === "opening" ? 0 : 4

    // The cat's awake while you type, and a while after.
    property bool catAwake: false

    Connections {
        target: root.control

        function onFailed(): void {
            shake.restart();
            field.text = "";
            root.wake();
        }
        function onReset(): void {
            field.text = "";
        }
        function onRefocusRequested(): void {
            field.focusInput();
        }
    }

    function wake(): void {
        catAwake = true;
        doze.restart();
    }

    Timer {
        interval: Math.max(1, Math.round((Theme.values.layout?.lockClose ?? 400) / 4))
        repeat: true
        running: root.step !== root.target
        onTriggered: root.step += root.step < root.target ? 1 : -1
    }

    Timer {
        id: doze

        interval: 10000
        onTriggered: root.catAwake = false
    }

    Item {
        anchors.fill: parent
        opacity: root.step / 4

        Forest {
            anchors.fill: parent
        }
        Rectangle {
            anchors.fill: parent
            color: Theme.palette.shadow
            opacity: 0.3
        }

        // Clicking anywhere puts the focus back in the input.
        MouseArea {
            anchors.fill: parent
            onClicked: root.control.refocus()
        }

        ColumnLayout {
            id: panel

            // Jitters on a wrong password: a few hops either way.
            property int hop: -1
            readonly property var hops: [-2, 2, -1, 1, 0]

            anchors.centerIn: parent
            anchors.horizontalCenterOffset: hop >= 0 ? hops[hop] * root.px : 0
            spacing: 18

            Timer {
                id: shake

                interval: 60
                repeat: true
                onTriggered: {
                    if (++panel.hop >= panel.hops.length) {
                        panel.hop = -1;
                        stop();
                    }
                }
                function restart(): void {
                    panel.hop = 0;
                    start();
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(root.control.now, "HH:mm")
                color: Theme.palette.accent
                font.pixelSize: 96
                font.weight: Font.DemiBold
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDate(root.control.now, "dddd d MMMM")
                caps: true
                color: Theme.palette.fg
                font.family: Theme.get("font.labels") ?? Theme.font.family
                font.pixelSize: Theme.font.size
            }

            // The window (primary screen only), the cat on top of it.
            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 72
                implicitWidth: 420
                implicitHeight: box.implicitHeight + 40
                visible: root.control.primary

                Frame {
                    anchors.fill: parent
                }

                // Twice the size it is on the bar: this is its place.
                Cat {
                    px: 2 * root.px
                    x: 4 * root.px
                    y: -7 * px
                    pose: root.catAwake || root.control.authState === "failed" ? "loaf" : "sleep"
                }

                ColumnLayout {
                    id: box

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 20
                    }
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        StyledText {
                            text: "Locked"
                            color: Theme.palette.accent
                            font.pixelSize: Theme.font.size + 6
                            font.weight: Font.DemiBold
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        StyledText {
                            text: `${root.control.user} @ ${root.control.hostname}`
                            caps: true
                            color: Theme.palette.dim
                            font.family: Theme.get("font.labels") ?? Theme.font.family
                            font.pixelSize: Theme.font.size - 3
                        }
                    }
                    TextField {
                        id: field

                        Layout.fillWidth: true
                        prompt: root.control.passcode > 0 ? "code" : "password"
                        placeholder: ""
                        echoMode: TextInput.Password
                        onAccepted: root.control.unlock(text)
                        onTextChanged: {
                            if (text !== "")
                                root.wake();
                            // Passcode mode: check as soon as enough is typed.
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
                        spacing: root.px * 2
                        visible: root.control.passcode > 0

                        Repeater {
                            model: root.control.passcode

                            Lamp {
                                required property int index

                                implicitWidth: 4 * root.px
                                implicitHeight: 4 * root.px
                                on: index < field.text.length
                                litColor: root.control.authState === "failed" ? Theme.palette.warn : Theme.palette.accent
                            }
                        }
                    }
                    StyledText {
                        text: root.control.authState === "checking" ? "checking…"
                            : root.control.authState === "failed" ? `wrong password · ${root.control.failures}`
                            : root.control.passcode > 0 ? "type your passcode" : "enter to unlock"
                        caps: true
                        color: root.control.authState === "failed" ? Theme.palette.warn : Theme.palette.dim
                        font.family: Theme.get("font.labels") ?? Theme.font.family
                        font.pixelSize: Theme.font.size - 3
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: root.control.authMessage
                        color: Theme.palette.muted
                        font.pixelSize: Theme.font.size - 2
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
}
