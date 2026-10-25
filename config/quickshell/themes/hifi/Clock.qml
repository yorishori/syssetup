import QtQuick
import QtQuick.Effects
import qs.core
import qs.modules.bar.widgets as W

// A red segment display behind smoked glass: the time in big seven-segment
// digits with a blinking colon, the date in small ones, and the days of the
// week printed along the top with today's lit. Unlit segments show faintly.
// Its bezel lights while the calendar is open.
Item {
    id: root

    required property W.Clock control
    readonly property color red: Theme.values.display?.clock ?? Theme.palette.error
    readonly property var days: ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]
    readonly property date now: control.now
    readonly property int weekday: (now.getDay() + 6) % 7
    property bool colon: true

    // Seven-segment digits lean a little.
    component Lean: Matrix4x4 {
        property real h
        matrix: Qt.matrix4x4(1, -0.1, 0, 0.1 * h / 2, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
    }

    implicitWidth: 200
    implicitHeight: 40

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: root.colon = !root.colon
    }

    Well {
        id: glass

        anchors.fill: parent
        fill: Qt.tint(Theme.palette.bgAlt, Qt.alpha(root.red, 0.05))
        ring: root.control.active ? Qt.alpha(root.red, 0.6) : root.control.hovered ? Qt.alpha(root.red, 0.25) : "transparent"
    }

    Item {
        anchors {
            fill: parent
            leftMargin: 9
            rightMargin: 9
        }
        layer.enabled: (Theme.glow.opacity ?? 0) > 0
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root.red
            shadowOpacity: Theme.glow.opacity ?? 0
            shadowBlur: 0.5
            blurMax: 12
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
        }

        Row {
            id: time

            anchors.verticalCenter: parent.verticalCenter
            height: 26
            spacing: 4
            transform: Lean { h: time.height }

            Segment7 { width: 15; height: parent.height; color: root.red; digit: Math.floor(root.now.getHours() / 10) }
            Segment7 { width: 15; height: parent.height; color: root.red; digit: root.now.getHours() % 10 }
            Item {
                width: 4
                height: parent.height

                Repeater {
                    model: [0.3, 0.7]

                    Rectangle {
                        required property real modelData

                        y: parent.height * modelData - 2
                        width: 4
                        height: 4
                        radius: 1
                        color: root.colon ? root.red : Qt.alpha(root.red, 0.09)
                    }
                }
            }
            Segment7 { width: 15; height: parent.height; color: root.red; digit: Math.floor(root.now.getMinutes() / 10) }
            Segment7 { width: 15; height: parent.height; color: root.red; digit: root.now.getMinutes() % 10 }
        }

        Column {
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            spacing: 4

            Row {
                spacing: 3

                Repeater {
                    model: root.days

                    Text {
                        required property int index
                        required property string modelData

                        text: modelData
                        color: index === root.weekday ? root.red : Qt.alpha(root.red, 0.16)
                        font.family: Theme.font.family
                        font.pixelSize: 8
                        font.bold: true
                    }
                }
            }
            Row {
                id: date

                anchors.right: parent.right
                height: 12
                spacing: 2
                transform: Lean { h: date.height }

                Segment7 { width: 7; height: parent.height; thickness: 1.6; color: root.red; digit: Math.floor(root.now.getDate() / 10) }
                Segment7 { width: 7; height: parent.height; thickness: 1.6; color: root.red; digit: root.now.getDate() % 10 }
                Rectangle {
                    y: parent.height - 2
                    width: 2
                    height: 2
                    color: root.red
                }
                Segment7 { width: 7; height: parent.height; thickness: 1.6; color: root.red; digit: Math.floor((root.now.getMonth() + 1) / 10) }
                Segment7 { width: 7; height: parent.height; thickness: 1.6; color: root.red; digit: (root.now.getMonth() + 1) % 10 }
            }
        }
    }

    Gloss {
        anchors {
            fill: parent
            margins: 1
        }
        roundness: glass.r
    }
}
