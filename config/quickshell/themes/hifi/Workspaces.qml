import QtQuick
import QtQuick.Effects
import qs.core
import qs.modules.bar.widgets as W

// A tuner: the workspaces are stations on a backlit dial, printed 10 to 70,
// and a red needle behind the glass points at the focused one. The needle
// swings over on a spring, overshooting and settling; the tuning knob beside
// the dial turns with it. Occupied stations have their marker lit.
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

    implicitWidth: dialWidth + 10 + knob.width
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
                readonly property bool active: root.control.active === wsId
                readonly property bool occupied: root.control.occupied(wsId)

                x: root.stationX(wsId) - width / 2
                width: root.step
                height: root.height

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 4
                    text: station.wsId * 10
                    color: root.ink
                    opacity: station.active ? 1 : root.control.hovered === station.wsId ? 0.85 : station.occupied ? 0.62 : 0.32
                    font.family: Theme.font.family
                    font.pixelSize: 13
                    font.bold: true

                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }
                }
                // The station's marker, lit while something is on it.
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 21
                    width: 5
                    height: 5
                    radius: 2.5
                    color: station.occupied ? root.ink : Qt.alpha(root.ink, 0.12)
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

    // The tuning knob, geared to the needle.
    Item {
        id: knob

        readonly property real turn: root.needleX * 1.6

        x: root.dialWidth + 10
        anchors.verticalCenter: parent.verticalCenter
        width: 34
        height: 34

        RectangularShadow {
            anchors.fill: parent
            radius: width / 2
            offset.y: 2
            blur: 6
            color: Qt.alpha(Theme.palette.shadow, Theme.values.effects?.shadow ?? 0)
        }
        // The knurled skirt.
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            border.width: 1
            border.color: Theme.palette.shadow
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.lighter(Theme.palette.surface, 1.3) }
                GradientStop { position: 1; color: Qt.darker(Theme.palette.surface, 1.6) }
            }
        }
        Item {
            anchors.fill: parent
            rotation: knob.turn

            Repeater {
                model: 24

                Rectangle {
                    required property int index

                    x: knob.width / 2 - 0.5
                    y: 1
                    width: 1
                    height: 4
                    color: Qt.alpha(Theme.palette.shadow, 0.8)
                    transform: Rotation {
                        origin.x: 0.5
                        origin.y: knob.height / 2 - 1
                        angle: index * 15
                    }
                }
            }
        }
        // The cap.
        Rectangle {
            anchors.centerIn: parent
            width: 24
            height: 24
            radius: 12
            border.width: 1
            border.color: Qt.alpha(Theme.palette.shadow, 0.8)
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.lighter(Theme.palette.border, 1.7) }
                GradientStop { position: 1; color: Qt.darker(Theme.palette.border, 1.2) }
            }
        }
        Item {
            anchors.fill: parent
            rotation: knob.turn

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 7
                width: 3
                height: 3
                radius: 1.5
                color: Theme.palette.shadow
            }
        }
    }
}
