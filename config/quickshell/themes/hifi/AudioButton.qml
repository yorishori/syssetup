import QtQuick
import QtQuick.Effects
import qs.core
import qs.modules.bar.widgets as W

// The volume knob, in a ring of LEDs lit up to the level. Scrolling turns
// it. Muted, it's pushed into the panel: it sinks, the ring goes dark and
// only the red LED at its foot is lit. Its pointer is backlit while
// something plays.
Row {
    id: root

    required property W.AudioButton control
    readonly property real level: Math.max(0, Math.min(1, control.volume))
    readonly property bool muted: control.off
    readonly property int leds: 13
    readonly property real ring: 21

    spacing: 4

    Legend {
        anchors.verticalCenter: parent.verticalCenter
        text: "vol"
        hovered: root.control.hovered
    }

    Item {
        id: dial

        property real angle: -135 + 270 * root.level

        anchors.verticalCenter: parent.verticalCenter
        width: 46
        height: 46

        Behavior on angle {
            SpringAnimation { spring: 5; damping: 0.4; epsilon: 0.2 }
        }

        // The ring, from -135 to 135 degrees, and the mute LED at the foot.
        Repeater {
            model: root.leds + 1

            Rectangle {
                required property int index
                readonly property bool isMute: index === root.leds
                readonly property real a: (isMute ? 180 : -135 + index * 270 / (root.leds - 1)) * Math.PI / 180
                readonly property bool lit: isMute ? root.muted : !root.muted && index <= Math.round(root.level * (root.leds - 1)) && root.level > 0
                readonly property color c: isMute ? Theme.palette.error : Theme.palette.accent

                x: dial.width / 2 + Math.sin(a) * root.ring - width / 2
                y: dial.height / 2 - Math.cos(a) * root.ring - height / 2
                width: 3
                height: 3
                radius: 1.5
                color: lit ? c : Qt.alpha(c, 0.12)

                RectangularShadow {
                    anchors.fill: parent
                    z: -1
                    visible: parent.lit && (Theme.glow.opacity ?? 0) > 0
                    radius: 1.5
                    blur: 4
                    color: Qt.alpha(parent.c, 0.8 * (Theme.glow.opacity ?? 0))
                }
            }
        }

        Item {
            id: knob

            anchors.centerIn: parent
            width: 32
            height: 32
            scale: root.muted ? 0.9 : 1

            Behavior on scale {
                NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
            }

            RectangularShadow {
                anchors.fill: parent
                radius: width / 2
                offset.y: 2
                blur: 6
                color: Qt.alpha(Theme.palette.shadow, root.muted ? 0 : (Theme.values.effects?.shadow ?? 0))
            }
            // The knurled skirt.
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                border.width: 1
                border.color: Theme.palette.shadow
                gradient: Gradient {
                    GradientStop { position: 0; color: root.muted ? Theme.palette.surface : Qt.lighter(Theme.palette.surface, 1.35) }
                    GradientStop { position: 1; color: Qt.darker(Theme.palette.surface, 1.7) }
                }
            }
            Item {
                anchors.fill: parent
                rotation: dial.angle

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
                width: 22
                height: 22
                radius: 11
                border.width: 1
                border.color: Qt.alpha(Theme.palette.shadow, 0.8)
                gradient: Gradient {
                    GradientStop { position: 0; color: root.muted ? Theme.palette.border : Qt.lighter(Theme.palette.border, 1.7) }
                    GradientStop { position: 1; color: Qt.darker(Theme.palette.border, 1.3) }
                }
            }
            // The pointer.
            Item {
                anchors.fill: parent
                rotation: dial.angle

                RectangularShadow {
                    anchors.fill: pointer
                    visible: root.control.playing && !root.muted && (Theme.glow.opacity ?? 0) > 0
                    blur: 5
                    color: Qt.alpha(Theme.palette.accent, 0.9 * (Theme.glow.opacity ?? 0))
                }
                Rectangle {
                    id: pointer

                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 6
                    width: 2
                    height: 9
                    radius: 1
                    color: root.control.playing && !root.muted ? Theme.palette.accent : Theme.palette.fg
                }
            }
        }
    }
}
