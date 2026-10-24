import QtQuick
import qs.core
import qs.modules.capture as M

// The shot, as a frame of film: the picture in its black film, sprocket
// holes along the edges. The tools are the edge printing along the bottom,
// in the film's orange: ▸ PEN, ▸ BOX… the one in hand printed bright; the
// inks as dots of themselves; UNDO; CANCEL and ▸ DONE at the far end. Where
// the bottom edge would be off the screen, it comes up over the picture.
Item {
    id: root

    required property M.MarkTools control

    readonly property rect a: control.area
    readonly property real rebate: 34
    readonly property real foot: 42
    readonly property real side: 10
    readonly property color film: "#121112"
    readonly property color edgeInk: "#e2953a"
    // A frame number, made up for the day.
    readonly property int frameNumber: 1 + new Date().getDate() % 36
    readonly property var names: ({ pen: "PEN", box: "BOX", arrow: "ARROW", mark: "MARK", block: "REDACT" })

    // A row of sprocket holes along a strip of film `length` long.
    component Holes: Row {
        property real length

        spacing: 9

        Repeater {
            model: Math.max(0, Math.floor((parent.length - 16) / 21))

            Rectangle {
                width: 12
                height: 13
                radius: 2
                color: "#d9d2c2"
                opacity: 0.85
            }
        }
    }

    // Edge printing to press: dim, brighter under the hand, bright when on.
    component Printed: Text {
        id: printed

        property bool on: false
        property bool usable: true

        signal pressed

        color: root.edgeInk
        opacity: !usable ? 0.25 : on ? 1 : hit.containsMouse ? 0.85 : 0.5
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
            enabled: printed.usable
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: printed.pressed()
        }
    }

    // ── The film ─────────────────────────────────────────────────────────────
    Item {
        id: strip

        x: root.a.x - root.side
        y: root.a.y - root.rebate
        width: root.a.width + 2 * root.side
        height: root.a.height + root.rebate

        // The film round the picture (the picture shows through its middle).
        Rectangle { width: parent.width; height: root.rebate; color: root.film }
        Rectangle { y: root.rebate; width: root.side; height: root.a.height; color: root.film }
        Rectangle { x: parent.width - root.side; y: root.rebate; width: root.side; height: root.a.height; color: root.film }

        // The top edge: the stock, by its holes.
        Item {
            width: strip.width
            height: root.rebate
            clip: true

            Holes {
                x: 8
                y: root.rebate - 6 - 13
                length: strip.width
            }
            Text {
                x: 14
                y: 2
                text: `HIFI SAFETY FILM 400        ${root.frameNumber}`
                color: root.edgeInk
                opacity: 0.85
                font.family: Theme.font.family
                font.pixelSize: 8
                font.bold: true
                font.letterSpacing: 1.5
            }
        }
    }

    // ── The bottom edge, with the tools printed on it ────────────────────────
    Item {
        readonly property real from: Math.max(0, strip.x)
        readonly property real shown: Math.min(root.width, strip.x + strip.width) - from
        // Room for all the printing: a narrow shot's edge runs on past it.
        readonly property real needed: tools.width + ends.width + 60

        x: needed > shown ? Math.max(0, Math.min(root.width - width, strip.x + strip.width / 2 - width / 2)) : from
        y: Math.min(root.a.y + root.a.height, root.height - root.foot)
        width: Math.max(shown, needed)
        height: root.foot
        clip: true

        Rectangle {
            anchors.fill: parent
            color: root.film
        }
        Holes {
            x: 8
            y: 6
            length: parent.width
        }

        // Left: the tools, the inks, undo.
        Row {
            id: tools

            x: 14
            y: 24
            spacing: 14

            Repeater {
                model: root.control.tools

                Printed {
                    required property var modelData

                    text: `▸ ${root.names[modelData.key] ?? modelData.key.toUpperCase()}`
                    on: root.control.tool === modelData.key
                    onPressed: root.control.toolPicked(modelData.key)
                }
            }
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Repeater {
                    model: root.control.inks

                    Item {
                        id: dot

                        required property color modelData
                        readonly property bool on: Qt.colorEqual(root.control.ink, modelData)

                        width: 12
                        height: 12

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: "transparent"
                            border.width: 1.5
                            border.color: root.edgeInk
                            visible: dot.on
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: 7
                            height: 7
                            radius: 3.5
                            color: dot.modelData
                            opacity: dot.on || inkArea.containsMouse ? 1 : 0.6
                        }
                        MouseArea {
                            id: inkArea

                            anchors {
                                fill: parent
                                margins: -4
                            }
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.control.inkPicked(dot.modelData)
                        }
                    }
                }
            }
            Printed {
                text: "↶ UNDO"
                usable: root.control.canUndo
                onPressed: root.control.undone()
            }
        }

        // Right: cancel, done.
        Row {
            id: ends

            anchors {
                right: parent.right
                rightMargin: 14
            }
            y: 24
            spacing: 18

            Printed {
                text: "CANCEL"
                onPressed: root.control.cancelled()
            }
            Printed {
                text: `▸ DONE  ${root.frameNumber}A`
                on: true
                onPressed: root.control.done()
            }
        }
    }
}
