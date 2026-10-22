import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.core
import qs.modules.notifications as M

// The teleprinter in the panel prints a slip: a strip of its paper feeds
// out of a slot in the panel's bottom edge, under the message counter, the
// new message typing out on it as it comes. More while it's out print onto
// the same strip (up to three, the newest by the slot); it's pulled back
// in once they're all done. Hovering it holds it out; click a message to act
// on it, its tear tab (or a right click) tears it off. Critical ones print
// in red and stay until dealt with.
//
// Over a fullscreen window the panel's hidden, so nothing comes out but the
// critical, on a thin red-edged slip from the top edge of the screen, one
// line each, as if from the panel up there.
Item {
    id: root

    required property M.PopupStack control

    readonly property real slipWidth: 300
    readonly property color paper: "#f7f4ea"
    readonly property color ink: "#23222a"
    readonly property color redInk: "#b8261b"
    // Where the slot is: under the panel, or the top of the screen over a
    // fullscreen window.
    readonly property real slotY: control.fullscreen ? 0 : control.barHeight - 1
    readonly property bool edge: control.fullscreen
    // What's printed on the slip: the newest three (only the critical over a
    // fullscreen window), newest first.
    readonly property var printing: (edge ? control.popups.filter(n => control.critical(n)) : control.popups).slice(0, 3)
    // What the slip shows: what's printing, kept while it's pulled back in.
    property var shown: []
    // The newest, typing out (0-1).
    property var typing: null
    property real typed: 1
    property bool held: hover.hovered

    // What takes input: where the slip is out (at the top level, in window
    // coordinates).
    readonly property Item inputArea: slipArea

    onPrintingChanged: {
        if (printing.length > 0) {
            if (printing[0] !== shown[0] && !shown.includes(printing[0])) {
                typing = printing[0];
                typeOut.restart();
            }
            shown = printing;
        }
    }

    NumberAnimation {
        id: typeOut

        target: root
        property: "typed"
        from: 0
        to: 1
        duration: Math.min(1600, 16 * ((root.typing?.summary?.length ?? 0) + root.control.plain(root.typing).length + 20))
    }

    // A cut end of the paper: fine teeth along it.
    component Serration: Shape {
        id: teeth

        width: parent?.width ?? 0
        height: 2

        ShapePath {
            strokeColor: "transparent"
            fillColor: root.paper
            startX: 0
            startY: 0

            PathPolyline {
                path: {
                    const pts = [];
                    for (let x = 0; x <= teeth.width; x += 2.4)
                        pts.push(Qt.point(x, 0), Qt.point(x + 1.2, teeth.height));
                    pts.push(Qt.point(teeth.width, 0));
                    return pts;
                }
            }
        }
    }

    Item {
        id: slipArea

        x: slip.x
        y: mouth.y
        width: slip.width
        height: slip.length
    }

    // Out of the slot: everything above it is clipped away, inside the panel.
    Item {
        id: mouth

        y: root.slotY
        width: root.width
        height: root.height - y
        clip: true

        Item {
            id: slip

            readonly property real target: root.printing.length > 0 ? blocks.implicitHeight + 14 : 0
            property real length: target

            x: Math.max(8, Math.min(root.width - root.slipWidth - 8,
                root.control.slotX >= 0 && !root.edge ? root.control.slotX - root.slipWidth / 2 : root.width - root.slipWidth - 24))
            width: root.slipWidth
            height: length

            // It feeds out as it prints; it's pulled back in briskly.
            Behavior on length {
                NumberAnimation {
                    duration: slip.target > slip.length ? 340 : 260
                    easing.type: slip.target > slip.length ? Easing.OutQuad : Easing.InCubic
                }
            }
            onLengthChanged: if (length === 0 && root.printing.length === 0) root.shown = []

            HoverHandler {
                id: hover
            }

            RectangularShadow {
                anchors.fill: parent
                offset.y: 4
                blur: 12
                color: Qt.alpha("black", 0.45 * (Theme.values.effects?.shadow ?? 0.6))
                visible: slip.length > 1
            }
            Rectangle {
                anchors.fill: parent
                color: root.paper
            }
            // Its red edge, over a fullscreen window.
            Rectangle {
                width: 3
                height: parent.height
                color: root.redInk
                visible: root.edge
            }
            // The sprocket holes, with the paper's end.
            Item {
                anchors.fill: parent
                clip: true
                visible: !root.edge

                Repeater {
                    model: 2

                    Column {
                        required property int index

                        x: index ? slip.width - 12 : 5
                        y: slip.height - height
                        spacing: 9

                        Repeater {
                            model: Math.ceil(blocks.implicitHeight / 16) + 2

                            Rectangle {
                                width: 7
                                height: 7
                                radius: 3.5
                                color: "#1d1d20"
                                opacity: 0.85
                            }
                        }
                    }
                }
                Repeater {
                    model: [17, slip.width - 18]

                    Rectangle {
                        required property real modelData

                        x: modelData
                        width: 1
                        height: slip.height
                        color: Qt.alpha(root.ink, 0.12)
                    }
                }
            }
            Serration {
                y: slip.height - 0.5
                visible: slip.length > 1
            }

            // The messages, the oldest at the paper's end, the newest by the
            // slot.
            Column {
                id: blocks

                x: root.edge ? 12 : 24
                y: slip.height - implicitHeight - 6
                width: slip.width - (root.edge ? 20 : 48)

                Repeater {
                    model: root.shown

                    Item {
                        id: block

                        required property var modelData
                        required property int index
                        readonly property bool critical: root.control.critical(modelData)
                        readonly property real progress: modelData === root.typing ? root.typed : 1
                        readonly property string head: {
                            const at = root.control.receivedAt(modelData);
                            return `${at ? Qt.formatTime(at, "HH:mm") : Qt.formatTime(new Date(), "HH:mm")}  ${(modelData?.appName ?? "").toUpperCase()}`;
                        }
                        readonly property string summary: modelData?.summary ?? ""
                        readonly property string body: root.edge ? "" : root.control.plain(modelData)
                        readonly property int chars: Math.round(progress * (head.length + summary.length + body.length))
                        property real tear: 0

                        width: blocks.width
                        height: lines.implicitHeight + (root.edge ? 10 : 20)

                        // Goes after its time, unless held or it stays.
                        Timer {
                            interval: root.control.timeout(block.modelData) * 1000
                            running: interval > 0 && !root.held && root.printing.includes(block.modelData)
                            onTriggered: root.control.hide(block.modelData)
                        }
                        SequentialAnimation {
                            id: tearing

                            NumberAnimation { target: block; property: "tear"; to: 1; duration: 260; easing.type: Easing.InCubic }
                            ScriptAction { script: root.control.dismiss(block.modelData) }
                        }

                        Item {
                            anchors.fill: parent
                            x: block.tear * 50
                            rotation: block.tear * 6
                            opacity: 1 - block.tear

                            Column {
                                id: lines

                                y: root.edge ? 5 : 9
                                width: parent.width
                                spacing: 2

                                Text {
                                    width: parent.width
                                    text: root.edge ? `${block.head}  ${block.summary}`.slice(0, block.chars)
                                        : block.head.slice(0, block.chars)
                                    elide: Text.ElideRight
                                    color: Qt.alpha(block.critical ? root.redInk : root.ink, root.edge ? 1 : 0.6)
                                    font.family: Theme.font.family
                                    font.pixelSize: root.edge ? 11 : 10
                                    font.bold: root.edge
                                    font.letterSpacing: 1
                                }
                                Text {
                                    width: parent.width
                                    text: block.summary.slice(0, Math.max(0, block.chars - block.head.length))
                                    elide: Text.ElideRight
                                    color: block.critical ? root.redInk : root.ink
                                    font.family: Theme.font.family
                                    font.pixelSize: 13
                                    font.bold: true
                                    visible: !root.edge
                                }
                                Text {
                                    width: parent.width
                                    text: block.body.slice(0, Math.max(0, block.chars - block.head.length - block.summary.length))
                                    elide: Text.ElideRight
                                    color: Qt.alpha(block.critical ? root.redInk : root.ink, 0.85)
                                    font.family: Theme.font.family
                                    font.pixelSize: 11
                                    visible: block.body !== ""
                                }
                            }
                            // The perforation between messages.
                            Row {
                                y: parent.height - 1
                                spacing: 4
                                visible: block.index < root.shown.length - 1

                                Repeater {
                                    model: Math.floor(block.width / 7)

                                    Rectangle {
                                        width: 3
                                        height: 1
                                        color: Qt.alpha(root.ink, 0.35)
                                    }
                                }
                            }
                            MouseArea {
                                id: blockArea

                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton)
                                        tearing.start();
                                    else
                                        root.control.invoke(block.modelData);
                                }

                                // The tear tab.
                                Rectangle {
                                    x: parent.width - width + 4
                                    y: parent.height - height - 2
                                    width: 18
                                    height: 14
                                    radius: 2
                                    color: tabArea.containsMouse ? "#e6dcc4" : "#efe8d6"
                                    border.width: 1
                                    border.color: Qt.alpha(root.ink, 0.3)
                                    visible: blockArea.containsMouse || tabArea.containsMouse

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✂"
                                        color: Qt.alpha(root.ink, 0.7)
                                        font.pixelSize: 10
                                    }
                                    MouseArea {
                                        id: tabArea

                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: tearing.start()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // In the slot's shadow, where it comes out.
            Rectangle {
                width: parent.width
                height: 8
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.alpha("black", 0.35) }
                    GradientStop { position: 1; color: "transparent" }
                }
                visible: !root.edge
            }
        }
    }
}
