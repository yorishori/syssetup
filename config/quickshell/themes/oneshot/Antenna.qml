import QtQuick
import qs.core

// A little lattice radio mast. While `sending`, rings go out from its tip,
// one more every couple of frames, the oldest fading; while `connecting`,
// a single ring blinks; `off` greys it out.
Item {
    id: root

    property bool sending: false
    property bool connecting: false
    property bool off: false
    property color color: Theme.palette.dim
    property color ringColor: Theme.palette.accent
    property int px: Theme.get("pixel.scale") ?? 3

    readonly property var mast: [
        "......x......",
        ".....xxx.....",
        "......x......",
        ".....x.x.....",
        ".....xxx.....",
        "....x...x....",
        "....xx.xx....",
        "...x.x.x.x...",
        "...xx...xx...",
        "..x..x.x..x..",
        "..xxx...xxx..",
        ".x...x.x...x.",
        ".xxxxxxxxxxx."
    ]
    readonly property var arcs: [
        ["x.", ".x", ".x", ".x", "x."],
        ["x..", ".x.", "..x", "..x", "..x", ".x.", "x.."],
        ["x...", ".x..", "..x.", "...x", "...x", "...x", "..x.", ".x..", "x..."]
    ]

    function rgba(c: color, a: real): string {
        return `rgba(${Math.round(c.r * 255)},${Math.round(c.g * 255)},${Math.round(c.b * 255)},${a})`;
    }

    implicitWidth: 23 * px
    implicitHeight: 14 * px

    Ticker { id: clock }

    PixelArt {
        x: 5 * root.px
        y: root.px
        px: root.px
        rows: root.mast
        colors: ({ "x": root.rgba(root.off ? Theme.palette.muted : root.color, 1) })
    }

    // The rings: arcs either side of the tip, the inner ones first.
    Repeater {
        model: 3

        Item {
            required property int index
            readonly property int step: clock.frame % 8
            readonly property bool shown: root.sending ? step >= index * 2 && step < 6 + index
                : root.connecting && index === 0 && clock.frame % 4 < 2
            readonly property real fade: root.sending ? 1 - Math.max(0, step - index * 2) * 0.15 : 1

            visible: shown && !root.off
            opacity: fade

            PixelArt {
                x: (11 + 2 + index * 2) * root.px + root.px
                y: (1.5 - index) * root.px
                px: root.px
                rows: root.arcs[index]
                colors: ({ "x": root.rgba(root.ringColor, 1) })
            }
            PixelArt {
                x: (11 - 2 - index * 2) * root.px - width + root.px
                y: (1.5 - index) * root.px
                px: root.px
                flip: true
                rows: root.arcs[index]
                colors: ({ "x": root.rgba(root.ringColor, 1) })
            }
        }
    }
}
