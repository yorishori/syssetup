import QtQuick
import qs.core

// A campfire: crossed logs ringed with stones, a flame flickering through
// three frames on the slow clock, sparks drifting up, a warm dithered glow.
Item {
    id: root

    property int px: Theme.get("pixel.scale") ?? 3

    implicitWidth: 30 * px
    implicitHeight: 26 * px

    Ticker { id: clock }

    Canvas {
        anchors.fill: parent
        antialiasing: false
        renderStrategy: Canvas.Immediate
        opacity: [1, 0.85, 1, 0.92][clock.frame % 4]

        onPaint: {
            const ctx = getContext("2d"), p = root.px;
            ctx.clearRect(0, 0, width, height);
            const cx = 15, cy = 15;
            for (let y = 0; y < 26; y++) {
                for (let x = 0; x < 30; x++) {
                    const d = Math.hypot(x - cx, (y - cy) * 1.3);
                    const share = d < 7 ? (x + y) % 2 === 0 : d < 12 ? x % 2 === 0 && y % 2 === 0 : d < 15 ? x % 4 === 0 && y % 2 === 0 : false;
                    if (!share)
                        continue;
                    ctx.fillStyle = "rgba(242,196,109,0.18)";
                    ctx.fillRect(x * p, y * p, p, p);
                }
            }
        }
    }

    // Sparks: a pixel rising from the fire and fading, a few at a time.
    Repeater {
        model: 4

        Rectangle {
            required property int index
            readonly property int t: (clock.frame + index * 3) % 12

            x: (13 + (index * 5) % 6 + (t % 4 === 1 ? 1 : 0)) * root.px
            y: (9 - t) * root.px
            width: root.px
            height: root.px
            color: index % 2 ? "#f2c46d" : "#ff9a2e"
            opacity: t < 8 ? 1 - t / 9 : 0
        }
    }

    PixelArt {
        x: 9 * root.px
        y: 7 * root.px
        px: root.px
        flip: clock.frame % 3 === 1
        colors: ({ "x": "#ef6f4f", "y": "#f2c46d", "z": "#fff1c9" })
        rows: clock.frame % 3 === 2 ? [
            "............",
            "......x.....",
            ".....xx.....",
            "....xxy.x...",
            "...xxyyxx...",
            "..xxyyzyx...",
            "..xyyzzyxx..",
            ".xxyzzzzyx..",
            ".xyyzzzzyyx.",
            ".xyzzzzzzyx.",
            "..xyzzzzyx..",
            "...xxxxxx..."
        ] : [
            ".....x......",
            ".....xx.....",
            "....xxx.....",
            "....xyx.x...",
            "...xxyxxx...",
            "..xxyyyxx...",
            "..xyyzyyx.x.",
            ".xxyzzzyxxx.",
            ".xyyzzzzyyx.",
            ".xyzzzzzzyx.",
            "..xyzzzzyx..",
            "...xxxxxx..."
        ]
    }
    PixelArt {
        x: 6 * root.px
        y: 17 * root.px
        px: root.px
        colors: ({ "o": "#5e4433", "d": "#33241c", "g": "#4a4466", "s": "#2c2840" })
        rows: [
            "dd..............dd",
            ".ooo..........ooo.",
            "...oooo....oooo...",
            "......oooooo......",
            "...oooo....oooo...",
            "gs.ddd.gsgs.ddd.gs",
            ".gsg..........gsg."
        ]
    }
}
