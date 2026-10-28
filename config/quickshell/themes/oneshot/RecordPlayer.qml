import QtQuick
import qs.core

// A little turntable: a record with dithered grooves and the album art
// (pixelated) on its label; while `playing` a glint goes round it, slowly,
// frame by frame, and the tonearm rests on the record. Paused, the arm
// swings back to its post.
Item {
    id: root

    property bool playing: false
    property string art: ""
    property int px: Theme.get("pixel.scale") ?? 3

    // In art pixels: the plinth is 30 x 26, the record 22 across.
    readonly property int r: 11
    readonly property int cx: 13
    readonly property int cy: 13

    implicitWidth: 30 * px
    implicitHeight: 26 * px

    Ticker { id: clock }

    Canvas {
        id: deck

        anchors.fill: parent
        antialiasing: false
        renderStrategy: Canvas.Immediate

        onPaint: {
            const ctx = getContext("2d"), p = root.px;
            const dot = (x, y, col) => {
                ctx.fillStyle = col;
                ctx.fillRect(x * p, y * p, p, p);
            };
            ctx.clearRect(0, 0, width, height);
            // The plinth: wood, a lighter top edge.
            ctx.fillStyle = "#4a3428";
            ctx.fillRect(0, 0, 30 * p, 26 * p);
            ctx.fillStyle = "#5e4433";
            ctx.fillRect(0, 0, 30 * p, p);
            ctx.fillStyle = "#33241c";
            ctx.fillRect(0, 25 * p, 30 * p, p);
            // The record: black, grooves dithered, a lighter rim.
            for (let y = -root.r; y <= root.r; y++) {
                for (let x = -root.r; x <= root.r; x++) {
                    const d = Math.hypot(x, y);
                    if (d > root.r + 0.3)
                        continue;
                    const groove = d > 5 && Math.round(d) % 2 === 0 && (x + y) % 2 === 0;
                    dot(root.cx + x, root.cy + y, d > root.r - 0.7 ? "#2a2533" : groove ? "#24202e" : "#141119");
                }
            }
            // The tonearm's post.
            ctx.fillStyle = "#8a8199";
            ctx.fillRect(26 * p, 3 * p, 2 * p, 2 * p);
        }
    }

    // The label: the album art, shrunk and blown up unsmoothed.
    Image {
        x: (root.cx - 4) * root.px
        y: (root.cy - 4) * root.px
        width: 9 * root.px
        height: 9 * root.px
        sourceSize: Qt.size(9, 9)
        smooth: false
        source: root.art
        visible: root.art !== ""
    }
    Rectangle {
        x: (root.cx - 4) * root.px
        y: (root.cy - 4) * root.px
        width: 9 * root.px
        height: 9 * root.px
        color: Theme.palette.accent
        visible: root.art === ""
    }
    Rectangle {
        x: root.cx * root.px
        y: root.cy * root.px
        width: root.px
        height: root.px
        color: "#141119"
    }

    // The glint going round, one of eight places per frame.
    Rectangle {
        readonly property real a: (clock.frame % 8) / 8 * 2 * Math.PI

        visible: root.playing
        x: Math.round(root.cx + Math.cos(a) * 8) * root.px
        y: Math.round(root.cy + Math.sin(a) * 8) * root.px
        width: 2 * root.px
        height: root.px
        color: "#8a8199"
    }

    // The tonearm: on the record while playing, back by its post when not.
    PixelArt {
        x: (root.playing ? 17 : 24) * root.px
        y: 3 * root.px
        px: root.px
        colors: ({ "a": "#cdbf9f", "h": "#8a8199" })
        rows: root.playing ? [
            ".........a",
            "........a.",
            ".......a..",
            "......a...",
            ".....a....",
            "....a.....",
            "...a......",
            "..a.......",
            ".hh.......",
            ".hh......."
        ] : [
            "...a",
            "...a",
            "...a",
            "...a",
            "...a",
            "...a",
            "...a",
            "..a.",
            ".hh.",
            ".hh."
        ]
    }
}
