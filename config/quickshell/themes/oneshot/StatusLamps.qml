import QtQuick
import qs.core
import qs.modules.bar.widgets as W

// Potion bubbles floating under the beam, one per thing the machine is
// doing on its own: a lavender one with a "zz" while it's idle, pumpkin ones
// with the mic, the camera or the screen while they're in use. Each rises
// in with a little wobble when it starts, bobs while it lasts, and pops
// when it stops. Hidden when there are none.
Row {
    id: root

    required property W.StatusLamps control
    // Still shown while the last one pops.
    readonly property bool shown: idle.life > 0 || mic.life > 0 || camera.life > 0 || screen.life > 0

    spacing: 4

    Ticker { id: clock }

    component Bubble: Item {
        id: bubble

        property bool on: false
        property string icon
        property color tint
        property int phase: 0
        // 0 gone, 1 there; eased in with an overshoot, straight out.
        property real life: on ? 1 : 0
        readonly property int px: 2

        Behavior on life {
            NumberAnimation {
                duration: bubble.on ? 380 : 220
                easing.type: bubble.on ? Easing.OutBack : Easing.Linear
                easing.overshoot: 2.2
            }
        }

        function rgba(c: color, a: real): string {
            return `rgba(${Math.round(c.r * 255)},${Math.round(c.g * 255)},${Math.round(c.b * 255)},${a})`;
        }

        anchors.verticalCenter: parent?.verticalCenter
        implicitWidth: 15 * px * Math.min(1, life)
        implicitHeight: 15 * px
        visible: life > 0

        Item {
            // Rises in from below; then bobs, a pixel at a time.
            readonly property int bob: [0, -1, -2, -1][(clock.frame + bubble.phase) % 4] * bubble.px

            anchors.horizontalCenter: parent.horizontalCenter
            width: 15 * bubble.px
            height: 15 * bubble.px
            y: (bubble.on ? (1 - Math.min(1, bubble.life)) * 12 : 0) + bob
            scale: bubble.on ? bubble.life : 1

            // The bubble: a round glassy outline, a tinted inside, a glint.
            PixelArt {
                visible: bubble.on
                px: bubble.px
                colors: ({ "o": bubble.rgba(bubble.tint, 0.95), "f": bubble.rgba(bubble.tint, 0.22), "g": "#fff6dc" })
                rows: [
                    ".....ooooo.....",
                    "...oofffffoo...",
                    "..ofgffffffffo.",
                    ".ofgfffffffffo.",
                    ".offfffffffffo.",
                    "offfffffffffffo",
                    "offfffffffffffo",
                    "offfffffffffffo",
                    "offfffffffffffo",
                    "offfffffffffffo",
                    ".offfffffffffo.",
                    ".offfffffffffo.",
                    "..offfffffffo..",
                    "...oofffffoo...",
                    ".....ooooo....."
                ]
            }
            Glyph {
                anchors.centerIn: parent
                visible: bubble.on
                text: bubble.icon
                color: bubble.tint
            }
            // Popped: a ring of droplets flying apart.
            PixelArt {
                anchors.centerIn: parent
                visible: !bubble.on
                opacity: bubble.life
                px: bubble.px
                colors: ({ "o": bubble.rgba(bubble.tint, 0.9) })
                rows: bubble.life > 0.5 ? [
                    "......o........",
                    "..o.......o....",
                    "...............",
                    "o.............o",
                    "...............",
                    "...............",
                    ".o...........o.",
                    "...............",
                    "....o.....o...."
                ] : [
                    "o.......o......",
                    "...............",
                    "..............o",
                    "...............",
                    "...............",
                    "o..............",
                    "...............",
                    "...............",
                    "......o.......o"
                ]
            }
        }
    }

    Bubble {
        id: idle

        on: root.control.idle
        icon: "\u{F04B2}"
        tint: Theme.palette.dim
        phase: 0
    }
    Bubble {
        id: mic

        on: root.control.mic
        icon: "\u{F036C}"
        tint: Theme.palette.warn
        phase: 1
    }
    Bubble {
        id: camera

        on: root.control.camera
        icon: "\u{F0567}"
        tint: Theme.palette.warn
        phase: 2
    }
    Bubble {
        id: screen

        on: root.control.screen
        icon: "\u{F1483}"
        tint: Theme.palette.warn
        phase: 3
    }
}
