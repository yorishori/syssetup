import QtQuick
import QtQuick.Effects
import qs.components as C
import qs.core
import qs.modules.lock as M

// Locked: the session screen's blast doors, shut. They slam across as it
// locks. On the left door, the time on a big red seven-segment display and
// the date under it; on the right door (the primary screen's), the access
// panel: who's locked out on its plate, a display that takes the password
// (a glowing dot for each letter; with a passcode, a lamp for each digit),
// what it's doing, and the power keys under it (reboot and power off ask
// twice). A wrong password lights its lamp red and the doors shudder.
Item {
    id: root

    required property M.LockView control

    readonly property color red: Theme.values.display?.clock ?? Theme.palette.error
    readonly property color vfd: Theme.palette.accent
    readonly property bool failed: control.authState === "failed"
    // The doors: 0 open, 1 shut; `jolt` shakes them.
    property real shut: 0
    property real jolt: 0

    Component.onCompleted: slam.start()

    Connections {
        target: root.control

        function onFailed(): void {
            field.text = "";
            shudder.restart();
        }
        function onReset(): void {
            field.text = "";
        }
        function onRefocusRequested(): void {
            field.forceActiveFocus();
        }
    }

    SequentialAnimation {
        id: slam

        NumberAnimation { target: root; property: "shut"; to: 1; duration: 420; easing.type: Easing.InQuad }
        ScriptAction { script: shudder.restart() }
    }
    SequentialAnimation {
        id: shudder

        NumberAnimation { target: root; property: "jolt"; to: 1; duration: 40 }
        NumberAnimation { target: root; property: "jolt"; to: -0.6; duration: 60 }
        NumberAnimation { target: root; property: "jolt"; to: 0.3; duration: 60 }
        NumberAnimation { target: root; property: "jolt"; to: 0; duration: 80 }
    }

    // The room, behind the doors.
    Rectangle {
        anchors.fill: parent
        color: Theme.palette.shadow
    }

    // Clicking anywhere puts the focus back in the panel.
    MouseArea {
        anchors.fill: parent
        onClicked: root.control.refocus()
    }

    Item {
        id: stage

        width: root.width
        height: root.height
        y: root.jolt * 7

        // ── The left door: the time ──────────────────────────────────────────
        BlastDoor {
            id: leftDoor

            x: -width * (1 - root.shut)
            width: root.width / 2 + depth / 2
            height: root.height

            Column {
                x: leftDoor.width - leftDoor.edgeWidth - 80 - width
                anchors.verticalCenter: parent.verticalCenter
                spacing: 16

                // The display, in its window.
                Item {
                    width: digits.width + 48
                    height: 150

                    Well {
                        anchors.fill: parent
                        roundness: 6
                        fill: Qt.tint("#0a0505", Qt.alpha(root.red, 0.04))
                    }
                    Row {
                        id: digits

                        readonly property string time: Qt.formatTime(root.control.now, "HHmm")

                        anchors.centerIn: parent
                        height: 104
                        spacing: 12

                        Repeater {
                            model: 2

                            Segment7 {
                                required property int index

                                width: 56
                                height: parent.height
                                thickness: 11
                                color: root.red
                                digit: Number(digits.time[index])
                            }
                        }
                        // The colon.
                        Item {
                            width: 14
                            height: parent.height

                            Repeater {
                                model: [0.3, 0.7]

                                Rectangle {
                                    required property real modelData

                                    y: parent.height * modelData - 6
                                    width: 12
                                    height: 12
                                    radius: 6
                                    color: root.red
                                }
                            }
                        }
                        Repeater {
                            model: 2

                            Segment7 {
                                required property int index

                                width: 56
                                height: parent.height
                                thickness: 11
                                color: root.red
                                digit: Number(digits.time[index + 2])
                            }
                        }
                    }
                    Gloss {
                        anchors {
                            fill: parent
                            margins: 1
                        }
                        roundness: 6
                    }
                }
                Silk {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(root.control.now, "dddd d MMMM")
                    font.pixelSize: 15
                    tracking: 4
                }
            }
        }

        // ── The right door: the access panel ─────────────────────────────────
        BlastDoor {
            id: rightDoor

            edge: "left"
            phase: period / 2
            x: root.width - width * root.shut
            width: root.width / 2 + depth / 2
            height: root.height

            Item {
                id: panel

                x: rightDoor.edgeWidth + 80
                anchors.verticalCenter: parent.verticalCenter
                width: 400
                height: inside.height + 48
                visible: root.control.primary

                Metal {
                    anchors.fill: parent
                    raised: true
                }
                Repeater {
                    model: [[0, 0], [1, 0], [0, 1], [1, 1]]

                    Screw {
                        required property var modelData

                        x: modelData[0] ? panel.width - width - 8 : 8
                        y: modelData[1] ? panel.height - height - 8 : 8
                        angle: 20 + 50 * modelData[0] + 30 * modelData[1]
                    }
                }

                Column {
                    id: inside

                    x: 28
                    y: 24
                    width: panel.width - 56
                    spacing: 14

                    // Who's locked out, on its plate.
                    Row {
                        spacing: 10

                        Led {
                            anchors.verticalCenter: parent.verticalCenter
                            size: 9
                            on: true
                            color: root.failed ? Theme.palette.error : root.vfd
                        }
                        Silk {
                            anchors.verticalCenter: parent.verticalCenter
                            text: `${root.control.user} @ ${root.control.hostname}`
                            font.pixelSize: 12
                        }
                    }

                    // The display, taking the password.
                    Item {
                        width: parent.width
                        height: 54

                        Well {
                            id: glass

                            anchors.fill: parent
                            roundness: 4
                            fill: Qt.tint("#050807", Qt.alpha(root.vfd, 0.05))
                        }
                        TextInput {
                            id: field

                            anchors.fill: parent
                            opacity: 0
                            echoMode: TextInput.Password
                            onAccepted: root.control.unlock(text)
                            // Passcode: checked as soon as it's all there.
                            onTextChanged: {
                                if (root.control.passcode > 0 && text.length === root.control.passcode)
                                    root.control.unlock(text);
                            }
                            // Never let the focus wander off.
                            onActiveFocusChanged: {
                                if (!activeFocus)
                                    Qt.callLater(root.control.refocus);
                            }
                            Component.onCompleted: root.control.refocus()
                        }
                        Row {
                            x: 16
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 9
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowColor: root.vfd
                                shadowBlur: 0.5
                                shadowHorizontalOffset: 0
                                shadowVerticalOffset: 0
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "▸"
                                color: root.vfd
                                font.family: Theme.font.family
                                font.pixelSize: 15
                            }
                            // A dot for each letter (up to what fits), or a lamp
                            // per passcode digit.
                            Repeater {
                                model: root.control.passcode > 0 ? root.control.passcode : Math.min(field.text.length, 24)

                                Rectangle {
                                    required property int index
                                    readonly property bool lit: root.control.passcode === 0 || index < field.text.length

                                    anchors.verticalCenter: parent.verticalCenter
                                    width: root.control.passcode > 0 ? 14 : 9
                                    height: width
                                    radius: width / 2
                                    color: lit ? root.vfd : "transparent"
                                    border.width: 1
                                    border.color: Qt.alpha(root.vfd, 0.5)
                                }
                            }
                            // The cursor.
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 2
                                height: 20
                                color: root.vfd
                                visible: root.control.passcode === 0 && field.activeFocus
                            }
                        }
                        Image {
                            anchors {
                                fill: parent
                                margins: 3
                            }
                            source: Qt.resolvedUrl("grille.png")
                            fillMode: Image.Tile
                            opacity: 0.3
                        }
                        Gloss {
                            anchors {
                                fill: parent
                                margins: 1
                            }
                            roundness: 4
                        }
                    }

                    // What it's doing.
                    Silk {
                        text: root.control.authState === "checking" ? "authenticating…"
                            : root.failed ? `access denied · ${String(root.control.failures).padStart(2, "0")}`
                            : root.control.passcode > 0 ? "type your passcode" : "enter to unlock"
                        color: root.failed ? Theme.palette.error : Theme.palette.fg
                        font.pixelSize: 11
                    }
                    Silk {
                        width: parent.width
                        text: root.control.authMessage
                        wrapMode: Text.Wrap
                        font.pixelSize: 10
                        opacity: 0.75
                        visible: text !== ""
                    }

                    // The power keys.
                    Row {
                        spacing: 10
                        topPadding: 6

                        C.TextButton {
                            text: root.control.armed === "reboot" ? "confirm?" : "reboot"
                            lit: root.control.armed === "reboot"
                            onClicked: root.control.power("reboot")
                        }
                        C.TextButton {
                            text: "sleep"
                            onClicked: root.control.power("sleep")
                        }
                        C.TextButton {
                            text: root.control.armed === "poweroff" ? "confirm?" : "power off"
                            lit: root.control.armed === "poweroff"
                            onClicked: root.control.power("poweroff")
                        }
                    }
                }
            }
        }
    }
}
