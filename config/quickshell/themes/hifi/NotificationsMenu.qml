import QtQuick
import qs.components as C
import qs.core
import qs.modules.notifications as M

// A split-flap board in a drawer, like the message counter on the panel: a
// row per notification, newest at the top, its time, who it's from and what
// it says on flap cards (in red for the critical, their lamps lit). When
// the board changes, the cards flip through to their new letters. Scroll
// (or the page keys) to flip to the next page of rows; click a row to act
// on it, its key to be done with it.
//
// Under the board: DO NOT DISTURB, a rocker, and the HOUR switch with the
// minutes left; CLEAR to clear the board. Under it all, a switch per
// source, labelled by hand.
Item {
    id: root

    required property M.NotificationsPanel control

    readonly property real margin: 12
    readonly property int rows: 7
    readonly property int timeChars: 5
    readonly property int fromChars: 11
    readonly property int messageChars: 22
    readonly property real cardWidth: 13
    readonly property real cardHeight: 21
    readonly property real pitch: cardWidth + 2
    readonly property real fieldGap: 12
    readonly property color redInk: "#ff5a48"
    readonly property color segRed: Theme.values.display?.clock ?? Theme.palette.error
    readonly property var all: control.history  // newest first
    readonly property int pages: Math.max(1, Math.ceil(all.length / rows))
    property int page: 0
    readonly property var showing: all.slice(page * rows, page * rows + rows)

    implicitWidth: unit.implicitWidth + 2 * margin
    implicitHeight: unit.implicitHeight + 2 * margin

    onPagesChanged: page = Math.min(page, pages - 1)

    // Text as it goes on the cards: capitals, plain letters, cut or padded to
    // `length`.
    function cards(text: string, length: int): string {
        const plain = (text ?? "").toUpperCase().normalize("NFD").replace(/[̀-ͯ]/g, "");
        return plain.slice(0, length).padEnd(length, " ");
    }
    function flip(step: int): void {
        page = Math.max(0, Math.min(pages - 1, page + step));
    }

    Connections {
        target: root.control

        function onOpenChanged(): void {
            root.page = 0;
        }
    }

    // A field of cards, showing `text`.
    component Field: Row {
        id: field

        property string text
        property color ink: "#f1eee6"

        spacing: root.pitch - root.cardWidth

        Repeater {
            model: field.text.length

            FlapChar {
                required property int index

                width: root.cardWidth
                height: root.cardHeight
                value: field.text[index]
                ink: field.ink
            }
        }
    }

    Framed {
        id: unit

        x: root.margin
        y: root.margin

        Column {
            spacing: 14

            Row {
                spacing: 12

                // ── The board ────────────────────────────────────────────────
                Column {
                    spacing: 6

                    // The columns' heads, printed over the board.
                    Item {
                        width: board.width
                        height: 12

                        Repeater {
                            model: [
                                ["time", 0],
                                ["from", root.timeChars * root.pitch + root.fieldGap],
                                ["message", (root.timeChars + root.fromChars) * root.pitch + 2 * root.fieldGap]
                            ]

                            Silk {
                                required property var modelData

                                x: 30 + modelData[1]
                                text: modelData[0]
                                font.pixelSize: 9
                            }
                        }
                    }
                    Item {
                        id: board

                        width: 30 + (root.timeChars + root.fromChars + root.messageChars) * root.pitch + 2 * root.fieldGap + 12
                        height: root.rows * (root.cardHeight + 7) + 14

                        Well {
                            anchors.fill: parent
                            roundness: 4
                            fill: "#0b0b0c"
                        }
                        Column {
                            x: 10
                            y: 8
                            spacing: 7

                            Repeater {
                                model: root.rows

                                Item {
                                    id: line

                                    required property int index
                                    readonly property var n: root.showing[index] ?? null
                                    readonly property bool critical: root.control.critical(n)
                                    readonly property color ink: critical ? root.redInk : "#f1eee6"

                                    width: board.width - 20
                                    height: root.cardHeight

                                    // Its lamp: lit for the critical.
                                    Led {
                                        anchors.verticalCenter: parent.verticalCenter
                                        size: 7
                                        on: line.critical
                                        color: Theme.palette.error
                                    }
                                    Row {
                                        x: 20
                                        spacing: root.fieldGap

                                        Field {
                                            text: root.cards(line.n ? Qt.formatTime(new Date(root.control.receivedAt(line.n) ?? Date.now()), "HH:mm") : "", root.timeChars)
                                            ink: Qt.alpha(line.ink, 0.8)
                                        }
                                        Field {
                                            text: root.cards(line.n?.appName ?? "", root.fromChars)
                                            ink: line.ink
                                        }
                                        Field {
                                            text: root.cards(line.n?.summary ?? "", root.messageChars)
                                            ink: line.ink
                                        }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: line.n !== null
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.control.invoke(line.n)
                                    }
                                }
                            }
                        }
                        Gloss {
                            anchors {
                                fill: parent
                                margins: 1
                            }
                            roundness: 4
                        }
                        // Scroll to flip through the pages.
                        WheelHandler {
                            onWheel: event => root.flip(event.angleDelta.y > 0 ? -1 : 1)
                        }
                    }
                }

                // A key per row, to be done with it; and the page keys.
                Column {
                    y: 18 + 8
                    spacing: 7

                    Repeater {
                        model: root.rows

                        Item {
                            required property int index
                            readonly property var n: root.showing[index] ?? null

                            width: 26
                            height: root.cardHeight

                            C.IconButton {
                                anchors.centerIn: parent
                                size: 22
                                icon: "\u{F012C}"
                                visible: parent.n !== null
                                onClicked: root.control.dismiss(parent.n)
                            }
                        }
                    }
                }
            }

            // ── The controls ─────────────────────────────────────────────────
            Row {
                spacing: 26

                // The pages.
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    C.IconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 26
                        icon: "\u{F0143}"
                        enabled: root.page > 0
                        opacity: enabled ? 1 : 0.4
                        onClicked: root.flip(-1)
                    }
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        Silk {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "page"
                        }
                        Flap {
                            width: 15
                            height: 24
                            value: Math.min(9, root.page + 1)
                        }
                        Silk {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "of"
                        }
                        Flap {
                            width: 15
                            height: 24
                            value: Math.min(9, root.pages)
                        }
                    }
                    C.IconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 26
                        icon: "\u{F0140}"
                        enabled: root.page < root.pages - 1
                        opacity: enabled ? 1 : 0.4
                        onClicked: root.flip(1)
                    }
                }

                // Do not disturb: a rocker, and the hour.
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        width: dnd.implicitWidth
                        height: dnd.implicitHeight

                        Rocker {
                            id: dnd

                            on: root.control.dnd
                            hovered: dndArea.containsMouse
                            lit: root.control.dnd
                            lampColor: Theme.palette.error
                        }
                        MouseArea {
                            id: dndArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.control.setDnd(!root.control.dnd, 0)
                        }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Silk {
                            text: "do not disturb"
                        }
                        Silk {
                            text: "critical gets through"
                            font.pixelSize: 8
                            opacity: 0.75
                        }
                    }
                    PushSwitch {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "1h"
                        latched: root.control.dndUntil > 0
                        onPushed: root.control.setDnd(true, 60)
                    }
                    // The hour's minutes left.
                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 40
                        height: 28

                        Well {
                            anchors.fill: parent
                            roundness: 3
                            fill: Qt.tint(Theme.palette.bgAlt, Qt.alpha(root.segRed, 0.05))
                        }
                        Row {
                            anchors.centerIn: parent
                            spacing: 3

                            Repeater {
                                model: 2

                                Segment7 {
                                    required property int index
                                    readonly property int minutes: Math.min(99, root.control.dndMinutesLeft)

                                    width: 11
                                    height: 18
                                    thickness: 2.4
                                    color: root.segRed
                                    digit: minutes > 0 ? (index === 0 ? Math.floor(minutes / 10) : minutes % 10) : -1
                                }
                            }
                        }
                    }
                }

                C.TextButton {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "clear"
                    enabled: root.all.length > 0
                    onClicked: root.control.clear()
                }
            }

            // ── The sources ──────────────────────────────────────────────────
            Framed {
                width: board.width + 12 + 26
                name: "sources"
                visible: root.control.apps.length > 0

                Flow {
                    width: parent.width
                    spacing: 16

                    Repeater {
                        model: root.control.apps

                        Column {
                            id: source

                            required property string modelData
                            readonly property bool open: !root.control.isMuted(modelData)

                            spacing: 6

                            Item {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: rocker.implicitWidth
                                height: rocker.implicitHeight

                                Rocker {
                                    id: rocker

                                    on: source.open
                                    hovered: sourceArea.containsMouse
                                    lit: source.open
                                }
                                MouseArea {
                                    id: sourceArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.control.toggleApp(source.modelData)
                                }
                            }
                            // Labelled by hand.
                            Legend {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: source.modelData.slice(0, 12)
                                size: 7
                            }
                        }
                    }
                }
            }
        }
    }
}
