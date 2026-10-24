import QtQuick
import qs.components as C
import qs.core
import qs.modules.capture as M

// The shot, as a frame of film: the picture in its black film, sprocket
// holes along the rebates, the edge printing by them (the frame's number,
// the stock). Under it (or over it, or in it, where there's room), a strip
// of the camera's metal: the tools as keys, the inks as color chips, undo;
// DONE and CANCEL.
Item {
    id: root

    required property M.MarkTools control

    readonly property rect a: control.area
    readonly property real rebate: 34
    readonly property real side: 10
    readonly property color film: "#121112"
    readonly property color edgeInk: "#e2953a"
    // A frame number, made up for the day.
    readonly property int frameNumber: 1 + new Date().getDate() % 36

    function clamp(v: real, lo: real, hi: real): real {
        return Math.max(lo, Math.min(hi, v));
    }

    // ── The film ─────────────────────────────────────────────────────────────
    Item {
        id: strip

        x: root.a.x - root.side
        y: root.a.y - root.rebate
        width: root.a.width + 2 * root.side
        height: root.a.height + 2 * root.rebate

        // The film round the picture (the picture shows through its middle).
        Rectangle { width: parent.width; height: root.rebate; color: root.film }
        Rectangle { y: parent.height - root.rebate; width: parent.width; height: root.rebate; color: root.film }
        Rectangle { y: root.rebate; width: root.side; height: root.a.height; color: root.film }
        Rectangle { x: parent.width - root.side; y: root.rebate; width: root.side; height: root.a.height; color: root.film }

        // The rebates: sprocket holes, and the edge printing outside them.
        Repeater {
            model: [0, 1]

            Item {
                id: rebate

                required property int modelData

                y: modelData ? strip.height - root.rebate : 0
                width: strip.width
                height: root.rebate
                clip: true

                Row {
                    x: 8
                    y: rebate.modelData ? 6 : root.rebate - 6 - 13
                    spacing: 9

                    Repeater {
                        model: Math.max(0, Math.floor((strip.width - 16) / 21))

                        Rectangle {
                            width: 12
                            height: 13
                            radius: 2
                            color: "#d9d2c2"
                            opacity: 0.85
                        }
                    }
                }
                Text {
                    x: 14
                    y: rebate.modelData ? root.rebate - height - 2 : 2
                    text: rebate.modelData ? `▸ ${root.frameNumber}        ▸ ${root.frameNumber}A`
                        : `HIFI SAFETY FILM 400        ${root.frameNumber}`
                    color: root.edgeInk
                    opacity: 0.85
                    font.family: Theme.font.family
                    font.pixelSize: 8
                    font.bold: true
                    font.letterSpacing: 1.5
                }
            }
        }
    }

    // ── The tools ────────────────────────────────────────────────────────────
    Item {
        readonly property real below: strip.y + strip.height + 12
        readonly property real above: strip.y - height - 12

        x: root.clamp(root.a.x + root.a.width / 2 - width / 2, 12, root.width - width - 12)
        y: below + height + 4 < root.height ? below
            : above > 0 ? above
            : root.a.y + root.a.height - height - 12
        width: tools.implicitWidth
        height: tools.implicitHeight

        Metal {
            anchors.fill: parent
            raised: true
        }
        Row {
            id: tools

            padding: 9
            spacing: 6

            Repeater {
                model: root.control.tools

                C.IconButton {
                    required property var modelData

                    anchors.verticalCenter: parent.verticalCenter
                    icon: modelData.glyph
                    lit: root.control.tool === modelData.key
                    onClicked: root.control.toolPicked(modelData.key)
                }
            }
            Item {
                width: 8
                height: 1
            }
            Repeater {
                model: root.control.inks

                Item {
                    required property color modelData

                    anchors.verticalCenter: parent.verticalCenter
                    width: 22
                    height: 22

                    C.Swatch {
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        color: parent.modelData
                        selected: Qt.colorEqual(root.control.ink, parent.modelData)
                        onClicked: root.control.inkPicked(parent.modelData)
                    }
                }
            }
            Item {
                width: 8
                height: 1
            }
            C.IconButton {
                anchors.verticalCenter: parent.verticalCenter
                icon: "\u{F054C}"
                enabled: root.control.canUndo
                opacity: enabled ? 1 : 0.4
                onClicked: root.control.undone()
            }
            C.TextButton {
                anchors.verticalCenter: parent.verticalCenter
                text: "done"
                lit: true
                onClicked: root.control.done()
            }
            C.TextButton {
                anchors.verticalCenter: parent.verticalCenter
                text: "cancel"
                onClicked: root.control.cancelled()
            }
        }
    }
}
