import QtQuick
import QtQuick.Effects
import qs.core
import qs.modules.compose as M

// A little keyboard of rubber keys, handed up from the bottom of the
// screen, that knows the compose sequences. Start one (' or a key on it)
// and the keys that can carry it on light up from under the rubber, each
// showing what it makes if it ends the sequence there (é on E, É with
// shift); the keys already typed stay down. Type or press the rest. Above
// the keys, a display: the sequence so far, everything it can still become
// (← → to pick, Enter for it) and the picked one's name. Type a word that
// starts no sequence and the display finds characters by name instead, and
// the keys to type the picked one light up, numbered in their order.
Item {
    id: root

    required property M.ComposePad control

    readonly property int columns: 16
    readonly property Item inputArea: unit
    readonly property bool showing: rise > 0.001
    readonly property real key: 44
    readonly property real pitch: 49
    readonly property color lamp: Theme.palette.accent
    // The keys, a row at a time: [unshifted, shifted], and each row's
    // indent in keys.
    readonly property var rows: [
        { indent: 0, keys: [["`", "~"], ["1", "!"], ["2", "@"], ["3", "#"], ["4", "$"], ["5", "%"], ["6", "^"], ["7", "&"], ["8", "*"], ["9", "("], ["0", ")"], ["-", "_"], ["=", "+"]] },
        { indent: 0.5, keys: [["q", "Q"], ["w", "W"], ["e", "E"], ["r", "R"], ["t", "T"], ["y", "Y"], ["u", "U"], ["i", "I"], ["o", "O"], ["p", "P"], ["[", "{"], ["]", "}"]] },
        { indent: 0.75, keys: [["a", "A"], ["s", "S"], ["d", "D"], ["f", "F"], ["g", "G"], ["h", "H"], ["j", "J"], ["k", "K"], ["l", "L"], [";", ":"], ["'", "\""], ["\\", "|"]] },
        { indent: 1.25, keys: [["z", "Z"], ["x", "X"], ["c", "C"], ["v", "V"], ["b", "B"], ["n", "N"], ["m", "M"], [",", "<"], [".", ">"], ["/", "?"]] }
    ]
    readonly property bool started: control.typed !== "" && !control.byName
    // Found by name: the picked one's keys.
    readonly property string howTo: control.byName ? (control.results[control.selected]?.seq ?? "") : ""
    // Up from the bottom edge (0-1).
    property real rise: 0

    Connections {
        target: root.control

        function onOpenChanged(): void {
            if (root.control.open) {
                drop.stop();
                handUp.restart();
            } else {
                handUp.stop();
                drop.restart();
            }
        }
        function onCleared(): void {
            field.text = "";
            if (root.control.open)
                field.forceActiveFocus();
        }
        function onSelectedChanged(): void {
            found.positionViewAtIndex(root.control.selected, GridView.Contain);
        }
    }
    NumberAnimation {
        id: handUp

        target: root
        property: "rise"
        to: 1
        duration: 460
        easing.type: Easing.OutBack
        easing.overshoot: 0.9
    }
    NumberAnimation {
        id: drop

        target: root
        property: "rise"
        to: 0
        duration: 220
        easing.type: Easing.InCubic
    }

    // Typed by pressing a key on it.
    function press(ch: string): void {
        field.text += ch;
        field.forceActiveFocus();
    }

    // ── The unit ─────────────────────────────────────────────────────────────
    Item {
        id: unit

        x: (parent.width - width) / 2
        y: parent.height - (height - 16) * root.rise
        width: 13 * root.pitch + 2 * 22
        height: 22 + display.height + 18 + 4 * root.pitch + 16 + 22 + 16
        visible: root.showing

        // Clicks on it stay on it.
        MouseArea {
            anchors.fill: parent
        }
        RectangularShadow {
            anchors.fill: parent
            radius: 14
            offset.y: 10
            blur: 30
            color: Qt.alpha("black", 0.65)
        }
        Rectangle {
            anchors.fill: parent
            radius: 14
            border.width: 1
            border.color: "#050506"
            gradient: Gradient {
                GradientStop { position: 0; color: "#26272b" }
                GradientStop { position: 0.12; color: "#1b1c1f" }
                GradientStop { position: 1; color: "#111214" }
            }
        }

        // ── The display ──────────────────────────────────────────────────────
        Item {
            id: display

            x: 22
            y: 22
            width: parent.width - 44
            height: 130

            Well {
                anchors.fill: parent
                roundness: 6
                fill: Qt.tint("#050807", Qt.alpha(root.lamp, 0.04))
            }

            // The sequence so far.
            Row {
                x: 14
                y: 12
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "▸"
                    color: root.lamp
                    font.family: Theme.font.family
                    font.pixelSize: 14
                }
                TextInput {
                    id: field

                    width: display.width - 240
                    color: root.lamp
                    selectionColor: Qt.alpha(root.lamp, 0.3)
                    selectedTextColor: root.lamp
                    font.family: Theme.font.family
                    font.pixelSize: 16
                    font.bold: true
                    font.letterSpacing: 4
                    clip: true
                    onTextChanged: root.control.typed = text
                    Keys.onPressed: event => event.accepted = root.control.fieldKey(event.key, event.modifiers)

                    Text {
                        anchors.fill: parent
                        text: "a sequence, or a name"
                        color: Qt.alpha(root.lamp, 0.3)
                        font.family: Theme.font.family
                        font.pixelSize: 13
                        visible: field.text === ""
                    }
                }
            }
            // How many.
            Text {
                anchors {
                    right: parent.right
                    rightMargin: 14
                }
                y: 15
                text: !root.control.loaded ? "LOADING"
                    : root.control.typed === "" ? `${root.control.sequences} SEQUENCES`
                    : root.control.byName ? `${root.control.results.length} BY NAME`
                    : `${root.control.results.length} TO GO`
                color: root.lamp
                opacity: 0.55
                font.family: Theme.font.family
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 1.5
            }

            // Everything it can still become.
            GridView {
                id: found

                x: 10
                y: 40
                width: parent.width - 20
                height: 2 * cellHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                cellWidth: Math.floor(width / root.columns)
                cellHeight: 30
                model: root.control.results

                delegate: Item {
                    id: cell

                    required property var modelData
                    required property int index
                    readonly property bool current: root.control.selected === index

                    width: found.cellWidth
                    height: found.cellHeight

                    Rectangle {
                        anchors {
                            fill: parent
                            margins: 2
                        }
                        radius: 3
                        color: Qt.alpha(root.lamp, 0.16)
                        border.width: 1
                        border.color: Qt.alpha(root.lamp, 0.6)
                        visible: cell.current
                    }
                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 4
                        horizontalAlignment: Text.AlignHCenter
                        text: cell.modelData.result
                        elide: Text.ElideRight
                        color: root.lamp
                        opacity: cell.current ? 1 : 0.75
                        font.family: Theme.font.family
                        font.pixelSize: 17
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.control.selected = cell.index
                        onClicked: root.control.insert(cell.modelData.result)
                    }
                }
            }
            Text {
                x: 14
                y: parent.height - 24
                width: parent.width - 28
                text: {
                    const r = root.control.results[root.control.selected];
                    if (!r)
                        return root.control.typed === "" ? "' e → é    o c → ©    - > → →" : "nothing goes that way";
                    return `${[...r.seq].join(" ")}   ${r.name}`.toUpperCase();
                }
                elide: Text.ElideRight
                color: root.lamp
                opacity: 0.6
                font.family: Theme.font.family
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 1.5
            }
            Gloss {
                anchors {
                    fill: parent
                    margins: 1
                }
                roundness: 6
            }
        }

        // ── The keys ─────────────────────────────────────────────────────────
        Column {
            x: 22
            y: display.y + display.height + 18
            spacing: root.pitch - root.key

            Repeater {
                model: root.rows

                Row {
                    id: keyRow

                    required property var modelData

                    leftPadding: keyRow.modelData.indent * root.pitch
                    spacing: root.pitch - root.key

                    Repeater {
                        model: keyRow.modelData.keys

                        Item {
                            id: cap

                            required property var modelData
                            readonly property string low: modelData[0]
                            readonly property string high: modelData[1]
                            readonly property bool letter: low !== high && low.toUpperCase() === high
                            readonly property var lowNext: root.control.next[low] ?? null
                            readonly property var highNext: root.control.next[high] ?? null
                            // Found by name: where it comes in typing the picked one (1, 2…,
                            // ⇧ for shifted; empty if not).
                            readonly property string steps: [...root.howTo].map((c, i) => c === low ? String(i + 1) : c === high ? `⇧${i + 1}` : "").filter(n => n).join(" ")
                            readonly property bool lit: root.started && (lowNext !== null || highNext !== null) || steps !== ""
                            // Down: typed in the sequence so far.
                            readonly property bool down: root.started && (root.control.typed.includes(low) || root.control.typed.includes(high))

                            width: root.key
                            height: root.key

                            // The light coming up round it.
                            RectangularShadow {
                                anchors.fill: rubber
                                radius: 7
                                blur: 12
                                color: Qt.alpha(root.lamp, 0.55)
                                visible: cap.lit
                            }
                            // Its side, gone when it's down.
                            Rectangle {
                                y: 3
                                width: parent.width
                                height: parent.height - 3
                                radius: 7
                                color: "#0b0b0d"
                                visible: !cap.down
                            }
                            Rectangle {
                                id: rubber

                                y: cap.down ? 2 : 0
                                width: parent.width
                                height: parent.height - 3
                                radius: 7
                                border.width: 1
                                border.color: cap.lit ? Qt.alpha(root.lamp, 0.8) : "#0a0a0b"
                                gradient: Gradient {
                                    GradientStop { position: 0; color: cap.lit ? Qt.tint("#4a4d54", Qt.alpha(root.lamp, 0.28)) : keyArea.containsMouse ? "#4c4f56" : "#3f4248" }
                                    GradientStop { position: 1; color: cap.lit ? Qt.tint("#33363c", Qt.alpha(root.lamp, 0.2)) : "#2c2e33" }
                                }
                                opacity: (root.started || root.howTo) && !cap.lit && !cap.down ? 0.45 : 1

                                // Its legends: the key (and, not a letter, its
                                // shifted one above).
                                Text {
                                    x: 6
                                    y: cap.letter ? 5 : 20
                                    text: cap.letter ? cap.high : cap.low
                                    color: "#e9e6de"
                                    font.family: Theme.font.family
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                                Text {
                                    x: 6
                                    y: 4
                                    text: cap.high
                                    visible: !cap.letter
                                    color: "#e9e6de"
                                    opacity: 0.7
                                    font.family: Theme.font.family
                                    font.pixelSize: 9
                                    font.bold: true
                                }
                                // What it makes, lit: shifted above, plain
                                // below; a dot if it only goes on.
                                Text {
                                    anchors {
                                        right: parent.right
                                        rightMargin: 5
                                    }
                                    y: 2
                                    text: cap.steps ? "" : cap.highNext?.result || (cap.highNext ? "·" : "")
                                    visible: cap.lit
                                    color: root.lamp
                                    font.family: Theme.font.family
                                    font.pixelSize: 13
                                }
                                Text {
                                    anchors {
                                        right: parent.right
                                        rightMargin: 5
                                        bottom: parent.bottom
                                        bottomMargin: 2
                                    }
                                    text: cap.steps || cap.lowNext?.result || (cap.lowNext ? "·" : "")
                                    visible: cap.lit
                                    color: root.lamp
                                    font.family: Theme.font.family
                                    font.pixelSize: 15
                                    font.bold: true
                                }
                            }
                            MouseArea {
                                id: keyArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mouse => root.press(mouse.modifiers & Qt.ShiftModifier ? cap.high : cap.low)
                            }
                        }
                    }
                }
            }
        }

        // How to use it, printed under the keys.
        Text {
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: 30
            }
            text: "TYPE OR PRESS   ← → PICK   ↵ INSERT   ESC CLOSE   ⇧ CLICK FOR SHIFT"
            color: "#e9e6de"
            opacity: 0.35
            font.family: Theme.font.family
            font.pixelSize: 8
            font.bold: true
            font.letterSpacing: 1.5
        }
    }
}
