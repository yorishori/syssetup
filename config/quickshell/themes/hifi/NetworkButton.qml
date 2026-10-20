import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.core
import qs.modules.bar.widgets as W

// A small oscilloscope printed LINK, its trace always running. Wi-Fi is a
// sine wave as tall as the signal is strong, Ethernet a clean square wave,
// connecting is noise, no connection a flat line, and with the radio off and
// no cable the screen goes dark.
Row {
    id: root

    required property W.NetworkButton control

    readonly property color phosphor: Theme.values.display?.scope ?? Theme.palette.ok
    readonly property string mode: control.wired ? "square"
        : !control.wifiEnabled ? "off"
        : control.connecting ? "noise"
        : control.online ? "sine"
        : "flat"
    readonly property real amplitude: mode === "sine" ? 0.25 + 0.7 * Math.max(0, Math.min(1, control.strength / 100))
        : mode === "square" ? 0.7
        : mode === "noise" ? 0.8
        : 0

    spacing: 6

    Legend {
        anchors.verticalCenter: parent.verticalCenter
        text: "link"
        color: root.control.hovered ? Theme.palette.fg : Theme.palette.dim
    }

    Item {
        id: screen

        // Two waves across the screen; the trace scrolls by one, endlessly.
        readonly property real period: (width - 6) / 2
        readonly property real mid: height / 2
        property real offset: 0
        // A fixed run of noise, one wave long, so it repeats seamlessly.
        readonly property var noise: Array.from({ length: Math.ceil(period / 2) + 1 }, () => Math.random() * 2 - 1)

        anchors.verticalCenter: parent.verticalCenter
        width: 84
        height: 38

        // The trace's points, across the screen and one more wave.
        function trace(): var {
            const points = [];
            const span = width - 6 + period;
            const half = (height - 10) / 2 * root.amplitude;
            for (let x = 0; x <= span; x += 1.5) {
                const t = x / period;
                let y = 0;
                if (root.mode === "sine")
                    y = Math.sin(t * 2 * Math.PI);
                else if (root.mode === "square")
                    y = (t % 1) < 0.5 ? 1 : -1;
                else if (root.mode === "noise")
                    y = noise[Math.floor((x % period) / 2)];
                points.push(Qt.point(x, mid - 3 - y * half));
            }
            return points;
        }

        // A steady 20 frames a second keeps the bar cheap to draw.
        Timer {
            interval: 50
            running: root.mode !== "off" && root.mode !== "flat"
            repeat: true
            onTriggered: screen.offset = (screen.offset + screen.period / 18) % screen.period
        }

        Well {
            id: tube

            anchors.fill: parent
            roundness: 7
            fill: root.mode === "off" ? "#050605" : Qt.tint("#040a06", Qt.alpha(root.phosphor, 0.05))
            ring: root.control.hovered ? Qt.alpha(root.phosphor, 0.45) : "transparent"
        }

        // The graticule.
        Item {
            anchors {
                fill: parent
                margins: 3
            }
            opacity: root.mode === "off" ? 0.3 : 1

            Repeater {
                model: 3

                Rectangle {
                    required property int index

                    x: (index + 1) * parent.width / 4
                    width: 1
                    height: parent.height
                    color: Qt.alpha(root.phosphor, 0.09)
                }
            }
            Rectangle {
                y: parent.height / 2
                width: parent.width
                height: 1
                color: Qt.alpha(root.phosphor, 0.14)
            }
        }

        // The beam.
        Item {
            anchors {
                fill: parent
                margins: 3
            }
            clip: true
            visible: root.mode !== "off"
            layer.enabled: (Theme.glow.opacity ?? 0) > 0
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: root.phosphor
                shadowOpacity: Theme.glow.opacity ?? 0
                shadowBlur: 0.45
                blurMax: 10
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
            }

            Shape {
                x: -screen.offset
                width: parent.width + screen.period
                height: parent.height
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeColor: root.phosphor
                    strokeWidth: 1.5
                    fillColor: "transparent"
                    joinStyle: ShapePath.RoundJoin

                    PathPolyline {
                        path: screen.trace()
                    }
                }
            }
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
