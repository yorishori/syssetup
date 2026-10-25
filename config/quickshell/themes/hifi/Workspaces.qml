import QtQuick
import QtQuick.Effects
import qs.components as C
import qs.core
import qs.modules.bar.widgets as W

// A tuner: the workspaces are stations on a dial, printed 10 to 70, and a
// red needle behind the glass points at the focused one. It travels over
// and settles on a spring. The numbers of the stations with something on
// them are lit from behind; the rest are only printed.
Item {
    id: root

    required property W.Workspaces control
    readonly property int stations: control.slots
    readonly property real step: 64
    readonly property real margin: 34
    readonly property real dialWidth: 2 * margin + (stations - 1) * step
    readonly property color ink: Theme.values.display?.dial ?? Theme.palette.fg
    readonly property color needleColor: Theme.values.display?.needle ?? Theme.palette.error
    readonly property real scaleLine: height - 8

    // Where the needle points: the focused station, or against the end stop.
    property real needleX: control.active < 1 ? margin / 3
        : control.active > stations ? dialWidth - margin / 3
        : stationX(control.active)

    function stationX(id: int): real {
        return margin + (id - 1) * step;
    }

    function workspaceAt(x: real): int {
        if (x < 0 || x > dialWidth)
            return 0;
        return Math.max(1, Math.min(stations, Math.round((x - margin) / step) + 1));
    }

    implicitWidth: dialWidth
    implicitHeight: 40

    // The needle runs at most so fast, so a long jump travels and then
    // settles, instead of overshooting by its length.
    Behavior on needleX {
        SpringAnimation { spring: 3; damping: 0.22; mass: 1; velocity: 700; epsilon: 0.1 }
    }

    Item {
        id: dial

        width: root.dialWidth
        height: root.height

        Well {
            id: glass

            anchors.fill: parent
            fill: Qt.tint("#0b0907", Qt.alpha(root.ink, 0.03))
        }

        // The lamps behind the dial, glowing warm through it.
        Item {
            anchors {
                fill: parent
                margins: 1
            }
            clip: true

            Repeater {
                model: [0.2, 0.8]

                RectangularShadow {
                    required property real modelData

                    x: dial.width * modelData - 60
                    y: dial.height * 0.45
                    width: 120
                    height: 14
                    radius: 7
                    blur: 34
                    color: Qt.alpha(root.ink, 0.2)
                }
            }
        }

        // The scale: ticks every fifth of a station, a line along them.
        Rectangle {
            x: root.margin - 2 * root.step / 5
            y: root.scaleLine
            width: (root.stations - 1) * root.step + 4 * root.step / 5 + 1
            height: 1
            color: Qt.alpha(root.ink, 0.35)
        }
        Repeater {
            model: (root.stations - 1) * 5 + 5

            Rectangle {
                required property int index
                readonly property bool major: (index - 2) % 5 === 0

                x: root.margin + (index - 2) * root.step / 5
                y: root.scaleLine - height
                width: 1
                height: major ? 6 : 3
                color: Qt.alpha(root.ink, major ? 0.55 : 0.3)
            }
        }

        Text {
            x: 7
            y: 5
            text: "WS"
            color: Qt.alpha(root.ink, 0.4)
            font.family: Theme.font.family
            font.pixelSize: 8
            font.bold: true
        }

        // The stations.
        Repeater {
            model: root.stations

            Item {
                id: station

                required property int index
                readonly property int wsId: index + 1
                readonly property bool lit: root.control.active === wsId || root.control.occupied(wsId)
                readonly property bool hovered: root.control.hovered === wsId

                x: root.stationX(wsId) - width / 2
                width: root.step
                height: root.scaleLine - 6

                C.StyledText {
                    anchors.centerIn: parent
                    text: station.wsId * 10
                    color: station.lit ? Qt.lighter(root.ink, 1.1) : root.ink
                    opacity: station.lit ? 1 : station.hovered ? 0.55 : 0.28
                    glow: station.lit
                    font.pixelSize: 14
                    font.bold: true

                    Behavior on opacity {
                        NumberAnimation { duration: 220 }
                    }
                }
            }
        }

        // The needle, between its end stops.
        Item {
            x: Math.max(root.margin / 3, Math.min(root.dialWidth - root.margin / 3, root.needleX)) - 1
            y: 3
            width: 2
            height: root.height - 6

            RectangularShadow {
                anchors.fill: parent
                visible: (Theme.glow.opacity ?? 0) > 0
                blur: 6
                spread: 1
                color: Qt.alpha(root.needleColor, 0.7 * (Theme.glow.opacity ?? 0))
            }
            Rectangle {
                anchors.fill: parent
                radius: 1
                color: root.needleColor
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
}
