import QtQuick
import QtQuick.Effects
import qs.core
import qs.modules.bar.widgets as W

// A fault printer: a slot in the panel printed FAULT. When part of the shell
// goes down, a strip of paper feeds out of it and hangs off the panel, one
// line per part; once all is well again it's drawn back in.
Item {
    id: root

    required property W.HealthIndicator control
    readonly property bool shown: true
    readonly property var lines: control.issues.map(i => `▲ ${i.toUpperCase()}`)
    property var printed: []

    implicitWidth: 64
    implicitHeight: 40

    // Keep the last text on the paper while it's drawn back in.
    onLinesChanged: if (lines.length > 0) printed = lines
    Component.onCompleted: printed = lines

    Legend {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 8
        text: "fault"
        color: root.lines.length > 0 ? Theme.palette.error : Theme.palette.dim
    }

    // The slot.
    Rectangle {
        id: slot

        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height - 10
        width: parent.width
        height: 5
        radius: 2.5
        color: Theme.palette.shadow

        Rectangle {
            anchors.top: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 4
            height: 1
            color: Qt.alpha("white", 0.12)
        }
    }

    // The tape, feeding out below the slot.
    Item {
        id: tape

        readonly property real full: paper.height + 5

        x: slot.x + 4
        y: slot.y + 3
        width: slot.width - 8
        height: root.lines.length > 0 ? full : 0
        clip: true
        visible: height > 0

        Behavior on height {
            NumberAnimation { duration: 700; easing.type: Easing.InOutSine }
        }

        Item {
            y: tape.height - tape.full
            width: tape.width
            height: tape.full

            RectangularShadow {
                anchors.fill: paper
                offset.y: 3
                blur: 6
                color: Qt.alpha(Theme.palette.shadow, Theme.values.effects?.shadow ?? 0)
            }
            Rectangle {
                id: paper

                width: parent.width
                height: text.implicitHeight + 8
                gradient: Gradient {
                    GradientStop { position: 0; color: "#cfc8b8" }
                    GradientStop { position: 0.15; color: "#eee8da" }
                    GradientStop { position: 1; color: "#e6dfcf" }
                }

                Column {
                    id: text

                    x: 4
                    y: 4

                    Repeater {
                        model: root.printed

                        Text {
                            required property string modelData

                            width: paper.width - 8
                            text: modelData
                            elide: Text.ElideRight
                            color: "#3b2f27"
                            font.family: Theme.font.family
                            font.pixelSize: 8
                            font.bold: true
                        }
                    }
                }
            }
            // The torn edge.
            Row {
                anchors.top: paper.bottom
                anchors.topMargin: -2.5

                Repeater {
                    model: Math.max(0, Math.ceil(tape.width / 5))

                    Rectangle {
                        width: 5
                        height: 5
                        rotation: 45
                        scale: 0.72
                        color: "#e6dfcf"
                    }
                }
            }
        }
    }
}
