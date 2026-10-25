import QtQuick
import QtQuick.Effects
import qs.core

// The uptime on a vacuum fluorescent display: glowing segments behind
// smoked glass and the fine grid of the tube's mesh, the host on tape.
Column {
    id: counter

    required property string hostname
    required property int uptime  // seconds
    property color vfd: Theme.palette.accent

    readonly property int hours: Math.floor(uptime / 3600)
    readonly property int minutes: Math.floor(uptime % 3600 / 60)

    spacing: 10

    Legend {
        text: hostname
        size: 14
    }

    Item {
        width: digits.x + digits.width + 18
        height: 60

        Well {
            id: tube

            anchors.fill: parent
            fill: Qt.tint("#050807", Qt.alpha(vfd, 0.05))
        }

        Item {
            anchors.fill: parent
            layer.enabled: (Theme.glow.opacity ?? 0) > 0
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: vfd
                shadowOpacity: Theme.glow.opacity ?? 0
                shadowBlur: 0.6
                blurMax: 16
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
            }

            Text {
                x: 10
                y: 8
                text: "UP"
                color: vfd
                font.family: Theme.font.family
                font.pixelSize: 10
                font.bold: true
            }

            Row {
                id: digits

                x: 36
                anchors.verticalCenter: parent.verticalCenter
                height: 34
                spacing: 6

                Segment7 { width: 18; height: parent.height; color: vfd; digit: counter.hours >= 100 ? Math.floor(counter.hours / 100) % 10 : -1 }
                Segment7 { width: 18; height: parent.height; color: vfd; digit: counter.hours >= 10 ? Math.floor(counter.hours / 10) % 10 : -1 }
                Segment7 { width: 18; height: parent.height; color: vfd; digit: counter.hours % 10 }
                Item {
                    width: 6
                    height: parent.height

                    Repeater {
                        model: [0.3, 0.7]

                        Rectangle {
                            required property real modelData

                            y: parent.height * modelData - 3
                            width: 6
                            height: 6
                            radius: 3
                            color: vfd
                        }
                    }
                }
                Segment7 { width: 18; height: parent.height; color: vfd; digit: Math.floor(counter.minutes / 10) }
                Segment7 { width: 18; height: parent.height; color: vfd; digit: counter.minutes % 10 }
            }
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
}
