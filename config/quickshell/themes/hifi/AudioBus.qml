import QtQuick
import Quickshell.Services.Pipewire
import qs.components as C
import qs.core
import qs.modules.audio as M

// The output or the input: its screen, a device selector, the profile's
// MODE selector, a horizontal fader with its scale printed above it, and
// the mute key.
Column {
    id: bus

    required property M.AudioPanel panel
    required property PwNode node
    required property var devices
    required property var profiles
    property string deviceLegend

    signal pick(var device)

    readonly property real volume: node?.audio?.volume ?? 0

    spacing: 6

    Item {
        width: row.width + 24
        height: row.height + 16

        SilkFrame {
            anchors.fill: parent
        }
        Row {
            id: row

            x: 12
            y: 8
            spacing: 12

            Readout {
                anchors.verticalCenter: parent.verticalCenter
                line1: bus.panel.nodeName(bus.node)
                line2: bus.profiles.switching ? "switching..." : bus.profiles.current?.label ?? ""
            }
            StepKnob {
                legend: bus.deviceLegend
                count: bus.devices.length
                index: bus.devices.indexOf(bus.node)
                onStepped: step => bus.pick(bus.devices[(index + step + count) % count])
            }
            StepKnob {
                legend: "mode"
                count: bus.profiles.list.length
                index: bus.profiles.list.findIndex(p => p.current)
                onStepped: step => bus.profiles.set(bus.profiles.list[(index + step + count) % count].index)
            }
            // The fader, its scale printed above.
            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: 196
                height: 44

                Repeater {
                    model: 11

                    Item {
                        required property int index
                        readonly property bool major: index % 2 === 0

                        x: 6 + index * (184 / 10) - width / 2
                        width: 14
                        height: 22

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: parent.index
                            visible: parent.major
                            color: Qt.alpha(Theme.palette.fg, 0.55)
                            font.family: Theme.font.family
                            font.pixelSize: 8
                        }
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            width: 1
                            height: parent.major ? 7 : 4
                            color: Qt.alpha(Theme.palette.fg, parent.major ? 0.5 : 0.3)
                        }
                    }
                }
                C.Meter {
                    x: 6
                    y: 28
                    width: 184
                    height: 12
                    value: bus.volume
                    color: "transparent"
                    onMoved: value => bus.panel.setLevel([bus.node], value)
                }
            }
            MuteKey {
                anchors.verticalCenter: parent.verticalCenter
                panel: bus.panel
                nodes: [bus.node]
            }
        }
    }
}
