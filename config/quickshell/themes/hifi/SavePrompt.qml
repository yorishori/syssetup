import QtQuick
import QtQuick.Effects
import qs.core
import qs.modules.capture as M

// What the capture's become, handed up from the bottom of the screen to be
// labelled: a screenshot, the frame cut from the film and mounted as a
// slide; a screen recording, a can of film; a voice memo, a cassette. Each
// has a label to write where it goes (the path, in pen) with the choices
// printed under it: ▸ SAVE (Enter), SAVE + COPY, COPY, DISCARD (Escape).
// Saved or not, it drops back out of sight.
Item {
    id: root

    required property M.SavePrompt control

    readonly property Item inputArea: thing
    readonly property bool showing: rise > 0.001
    readonly property color pen: "#1f3a8a"
    readonly property color printInk: "#3b3833"
    // Up from the bottom edge (0-1).
    property real rise: 0
    // Where it goes, and the label's field writing it.
    property string pathText
    property Item field: null

    function focusField(): void {
        if (!field)
            return;
        field.text = pathText;
        field.cursorPosition = field.text.length;
        field.forceActiveFocus();
    }

    implicitWidth: 520

    Connections {
        target: root.control

        function onAskingChanged(): void {
            if (root.control.asking) {
                drop.stop();
                root.pathText = root.control.suggestedName();
                Qt.callLater(root.focusField);
                handUp.restart();
            } else {
                handUp.stop();
                drop.restart();
            }
        }
    }
    NumberAnimation {
        id: handUp

        target: root
        property: "rise"
        to: 1
        duration: 460
        easing.type: Easing.OutBack
        easing.overshoot: 1.1
    }
    NumberAnimation {
        id: drop

        target: root
        property: "rise"
        to: 0
        duration: 230
        easing.type: Easing.InCubic
    }

    // The label: where it goes, in pen on a ruled line, and the choices
    // printed under it.
    component Label: Column {
        id: label

        property color paper: "#f3eee2"

        spacing: 8

        Item {
            width: label.width
            height: 22

            TextInput {
                id: field

                width: parent.width
                anchors.bottom: rule.top
                anchors.bottomMargin: 2
                color: root.pen
                selectionColor: Qt.alpha(root.pen, 0.25)
                selectedTextColor: root.pen
                font.family: Theme.font.family
                font.pixelSize: 12
                font.italic: true
                clip: true
                onTextEdited: root.pathText = text
                onAccepted: root.control.save(root.pathText, false)
                Component.onCompleted: {
                    root.field = field;
                    if (root.control.asking)
                        root.focusField();
                }
            }
            Rectangle {
                id: rule

                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Qt.alpha(root.printInk, 0.5)
            }
        }
        Row {
            spacing: 16

            Repeater {
                model: [
                    { text: "▸ SAVE ↵", act: () => root.control.save(root.pathText, false), shot: false, strong: true },
                    { text: "SAVE + COPY", act: () => root.control.save(root.pathText, true), shot: true },
                    { text: "COPY", act: () => root.control.copy(), shot: true },
                    { text: "DISCARD esc", act: () => root.control.discard(), shot: false }
                ].filter(c => !c.shot || root.control.isShot)

                Text {
                    required property var modelData

                    text: modelData.text
                    color: root.printInk
                    opacity: hit.containsMouse || modelData.strong ? 1 : 0.6
                    font.family: Theme.font.family
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 1.5

                    MouseArea {
                        id: hit

                        anchors {
                            fill: parent
                            margins: -5
                        }
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: parent.modelData.act()
                    }
                }
            }
        }
    }

    Item {
        id: thing

        x: (parent.width - width) / 2
        y: parent.height - (height + 24) * root.rise
        width: shown.item?.width ?? 0
        height: shown.item?.height ?? 0
        visible: root.showing
        rotation: -4 * (1 - root.rise)

        Loader {
            id: shown

            sourceComponent: root.control.isShot ? slide : root.control.kind === "screen" ? can : cassette
        }
    }

    // ── A slide ──────────────────────────────────────────────────────────────
    Component {
        id: slide

        Item {
            readonly property real fitW: Math.min(400, 260 * root.control.area.width / Math.max(1, root.control.area.height))
            readonly property real fitH: fitW * root.control.area.height / Math.max(1, root.control.area.width)

            width: Math.max(fitW + 48, 440)
            height: fitH + 30 + 100

            RectangularShadow {
                anchors.fill: parent
                radius: 10
                offset.y: 8
                blur: 26
                color: Qt.alpha("black", 0.6)
            }
            Rectangle {
                anchors.fill: parent
                radius: 10
                border.width: 1
                border.color: "#bdb5a2"
                gradient: Gradient {
                    GradientStop { position: 0; color: "#f6f2e8" }
                    GradientStop { position: 1; color: "#e6dfcf" }
                }
            }
            // The window, the frame in it.
            Rectangle {
                id: window

                x: (parent.width - width) / 2
                y: 30
                width: parent.fitW + 6
                height: parent.fitH + 6
                radius: 3
                color: "#121112"

                Image {
                    anchors {
                        fill: parent
                        margins: 3
                    }
                    source: root.control.isShot && root.control.asking ? "file://" + root.control.file : ""
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: false
                }
            }
            Text {
                x: window.x
                y: 10
                text: `${Math.round(root.control.area.width)}×${Math.round(root.control.area.height)}`
                color: root.printInk
                opacity: 0.6
                font.family: Theme.font.family
                font.pixelSize: 9
                font.bold: true
                font.letterSpacing: 1.5
            }
            Label {
                x: 24
                y: window.y + window.height + 18
                width: parent.width - 48
            }
        }
    }

    // ── A can of film ────────────────────────────────────────────────────────
    Component {
        id: can

        Item {
            width: 440
            height: 300

            RectangularShadow {
                anchors.fill: tin
                radius: tin.radius
                offset.y: 8
                blur: 26
                color: Qt.alpha("black", 0.6)
            }
            // The lid, seen from above: its rim and ridges.
            Rectangle {
                id: tin

                anchors.horizontalCenter: parent.horizontalCenter
                width: 300
                height: 300
                radius: 150
                border.width: 1
                border.color: "#2c2d31"
                gradient: Gradient {
                    GradientStop { position: 0; color: "#c9ccd2" }
                    GradientStop { position: 0.5; color: "#9ea2a9" }
                    GradientStop { position: 1; color: "#6f737a" }
                }

                Repeater {
                    model: [262, 236]

                    Rectangle {
                        required property int modelData

                        anchors.centerIn: parent
                        width: modelData
                        height: modelData
                        radius: modelData / 2
                        color: "transparent"
                        border.width: 1.5
                        border.color: Qt.alpha("white", 0.35)
                    }
                }
            }
            // Its label, taped across it.
            Rectangle {
                anchors.verticalCenter: tin.verticalCenter
                width: parent.width
                height: 128
                rotation: -1.5
                color: "#f3eee2"
                border.width: 1
                border.color: "#cfc7b4"

                Text {
                    x: 20
                    y: 12
                    text: `SCREEN RECORDING     ${root.control.duration(root.control.elapsed)}`
                    color: root.printInk
                    font.family: Theme.font.family
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 2
                }
                Label {
                    x: 20
                    y: 44
                    width: parent.width - 40
                }
            }
        }
    }

    // ── A cassette ───────────────────────────────────────────────────────────
    Component {
        id: cassette

        Item {
            width: 440
            height: 278

            RectangularShadow {
                anchors.fill: parent
                radius: 12
                offset.y: 8
                blur: 26
                color: Qt.alpha("black", 0.6)
            }
            Rectangle {
                anchors.fill: parent
                radius: 12
                border.width: 1
                border.color: "#050506"
                gradient: Gradient {
                    GradientStop { position: 0; color: "#2d2e33" }
                    GradientStop { position: 1; color: "#18191c" }
                }
            }
            // The label, and the window onto the reels through it.
            Rectangle {
                x: 18
                y: 16
                width: parent.width - 36
                height: 190
                radius: 4
                color: "#f3eee2"

                Rectangle {
                    width: parent.width
                    height: 26
                    radius: 4
                    color: "#d9692b"

                    Text {
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: `A   VOICE MEMO   ${root.control.duration(root.control.elapsed)}`
                        color: "#fbfaf5"
                        font.family: Theme.font.family
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 2
                    }
                }
                Label {
                    x: 14
                    y: 38
                    width: parent.width - 28
                }
                Rectangle {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                        bottomMargin: 14
                    }
                    width: 220
                    height: 58
                    radius: 29
                    color: "#121214"

                    Repeater {
                        model: [0, 1]

                        Item {
                            required property int modelData

                            x: modelData ? parent.width - 29 - 21 : 29 - 21
                            y: 29 - 21
                            width: 42
                            height: 42

                            Rectangle {
                                anchors.fill: parent
                                radius: 21
                                color: "#5a3a22"
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                width: 20
                                height: 20
                                radius: 10
                                color: "#e9e6de"

                                Repeater {
                                    model: 6

                                    Rectangle {
                                        required property int index

                                        x: 9
                                        y: 2
                                        width: 2
                                        height: 4
                                        color: "#121214"
                                        transform: Rotation {
                                            origin.x: 1
                                            origin.y: 8
                                            angle: index * 60
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            // The screws and the bottom edge's tape slot.
            Rectangle {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                }
                width: 260
                height: 48
                color: "#232428"
                border.width: 1
                border.color: "#0a0a0b"
            }
            Repeater {
                model: [[0, 0], [1, 0], [0, 1], [1, 1]]

                Screw {
                    required property var modelData

                    x: modelData[0] ? parent.width - width - 6 : 6
                    y: modelData[1] ? parent.height - height - 6 : 6
                    angle: 30 + modelData[0] * 40
                }
            }
        }
    }
}
