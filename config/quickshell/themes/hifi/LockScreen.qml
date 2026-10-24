import QtQuick
import QtQuick.Effects
import qs.core
import qs.modules.lock as M
import qs.modules.session as S

// Locked: the session screen's blast doors, shut. They slam across as it
// locks. On the left door, the time on a big red seven-segment display and
// the date under it; on the right door (the primary screen's), who's locked
// out on tape, a display behind smoked glass that takes the password (a
// glowing dot for each letter typed, nothing for those not), what it's
// doing, and the session screen's keys under it (reboot and power off ask
// twice). A wrong password lights its lamp red and the doors shudder; the
// right one draws the bolts and the doors part.
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
        function onUnlockingChanged(): void {
            if (root.control.unlocking) {
                slam.stop();
                open.start();
            }
        }
    }
    // The bolts drawn (a knock), then the doors part.
    SequentialAnimation {
        id: open

        NumberAnimation { target: root; property: "jolt"; to: -0.5; duration: 70 }
        NumberAnimation { target: root; property: "jolt"; to: 0; duration: 90 }
        NumberAnimation { target: root; property: "shut"; to: 0; duration: 480; easing.type: Easing.InOutCubic }
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

            // Who's locked out, on tape; the display that takes the
            // password; the session screen's keys under it.
            Column {
                id: panel

                x: rightDoor.edgeWidth + 80
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12
                visible: root.control.primary

                Legend {
                    text: `${root.control.user} @ ${root.control.hostname}`
                    size: 14
                }

                // The display: a dot for each letter typed, none for those
                // not (so it doesn't tell how long a passcode is), and under
                // it what it's doing; its lamp red when it's refused.
                Item {
                    width: 420
                    height: 86

                    Well {
                        id: tube

                        anchors.fill: parent
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
                    Item {
                        anchors.fill: parent
                        layer.enabled: (Theme.glow.opacity ?? 0) > 0
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: root.vfd
                            shadowOpacity: Theme.glow.opacity ?? 0
                            shadowBlur: 0.6
                            blurMax: 16
                            shadowHorizontalOffset: 0
                            shadowVerticalOffset: 0
                        }

                        Row {
                            x: 16
                            y: 14
                            height: 26
                            spacing: 8

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.control.passcode > 0 ? "CODE" : "PASS"
                                color: root.vfd
                                font.family: Theme.font.family
                                font.pixelSize: 10
                                font.bold: true
                            }
                            Repeater {
                                model: Math.min(field.text.length, 22)

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 10
                                    height: 10
                                    radius: 5
                                    color: root.vfd
                                }
                            }
                            // The cursor.
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 10
                                height: 3
                                color: root.vfd
                                visible: field.activeFocus && !root.control.unlocking
                            }
                        }
                        Text {
                            x: 16
                            y: parent.height - 28
                            text: root.control.unlocking ? "OPEN"
                                : root.control.authState === "checking" ? "CHECKING…"
                                : root.failed ? `DENIED · ${String(root.control.failures).padStart(2, "0")}`
                                : "ENTER TO UNLOCK"
                            color: root.vfd
                            opacity: 0.7
                            font.family: Theme.font.family
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 2
                        }
                    }
                    Led {
                        anchors {
                            right: parent.right
                            rightMargin: 16
                            verticalCenter: parent.verticalCenter
                        }
                        size: 10
                        on: true
                        color: root.failed ? Theme.palette.error : root.control.unlocking ? Theme.palette.ok : root.vfd
                    }
                    // The mesh.
                    Image {
                        anchors {
                            fill: parent
                            margins: 3
                        }
                        source: Qt.resolvedUrl("grille.png")
                        fillMode: Image.Tile
                        opacity: 0.35
                    }
                    Gloss {
                        anchors {
                            fill: parent
                            margins: 1
                        }
                        roundness: tube.r
                    }
                }
                Silk {
                    width: 420
                    text: root.control.authMessage
                    wrapMode: Text.Wrap
                    opacity: 0.8
                    visible: text !== ""
                }

                // The power keys: the session screen's, smaller.
                Row {
                    topPadding: 24
                    spacing: 8

                    Repeater {
                        model: [
                            { key: "reboot", label: "Reboot", glyph: "\u{F0709}", action: "reboot" },
                            { key: "sleep", label: "Sleep", glyph: "\u{F0904}", action: "sleep" },
                            { key: "shutdown", label: "Power off", glyph: "\u{F0425}", action: "poweroff" }
                        ]

                        Item {
                            required property var modelData

                            width: 130
                            height: 160

                            S.SessionKey {
                                width: 220
                                height: 222
                                scale: 0.58
                                transformOrigin: Item.TopLeft
                                key: parent.modelData.key
                                label: root.control.armed === parent.modelData.action ? "Again" : parent.modelData.label
                                glyph: parent.modelData.glyph
                                armed: root.control.armed === parent.modelData.action
                                onClicked: root.control.power(parent.modelData.action)
                            }
                        }
                    }
                }
            }
        }
    }
}
