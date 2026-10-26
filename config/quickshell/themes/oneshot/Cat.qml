import QtQuick
import qs.core

// The cat: black, a faint moonlit rim so it shows on dark plum, pumpkin
// eyes. It never talks and never gets in the way; it just lives in the
// shell. Poses:
//   loaf    lying on an edge, tail dangling over it (13 rows; the body is
//           the top 8, so put row 7 on the edge)
//   sit     sitting up (16 × 16)
//   sleep   the loaf, eyes shut, tail tucked, z's drifting up
//   nap     a loaf that dozes off now and then: awake for half a minute,
//           asleep for a minute
// It blinks and sways its tail on the theme's slow frame clock. `flip`
// faces it the other way (the tail on the left).
Item {
    id: root

    property string pose: "loaf"
    property bool flip: false
    property int px: Theme.get("pixel.scale") ?? 3

    readonly property bool lying: pose !== "sit"
    readonly property bool asleep: pose === "sleep" || (pose === "nap" && clock.frame % 360 >= 120)
    readonly property bool blinking: clock.frame % 28 === 27
    readonly property bool tailUp: clock.frame % 16 >= 8

    readonly property var colors: ({
        "O": "#4f4570",  // the rim
        "B": "#17141f",  // the black coat
        "L": "#1f1b29",  // its chest, a shade lighter
        "P": "#3a2a40",  // inside the ears, the nose
        "E": "#ff9a2e"   // pumpkin eyes
    })

    implicitWidth: (lying ? 18 : 16) * px
    implicitHeight: (lying ? 13 : 16) * px

    Ticker { id: clock }

    // Lying down.
    PixelArt {
        visible: root.lying
        px: root.px
        flip: root.flip
        colors: root.colors
        rows: [
            ".O....O...........",
            ".OO..OO...........",
            "OBBOOBBO.OOOOOO...",
            "OBBBBBBBOBBBBBBO..",
            "OBBBBBBBBBBBBBBBO.",
            "OBBBBBBBBBBBBBBBO.",
            ".OBBBBBBBBBBBBBBO.",
            "..OOOOOOOOOOOOOO.."
        ]
    }
    PixelArt {
        visible: root.lying && !root.asleep && !root.blinking
        px: root.px
        flip: root.flip
        colors: root.colors
        rows: [
            "..................",
            "..................",
            "..................",
            "..E..E............",
            "..E..E............"
        ]
    }
    PixelArt {
        visible: root.lying && (root.asleep || root.blinking)
        px: root.px
        flip: root.flip
        colors: root.colors
        rows: [
            "..................",
            "..................",
            "..................",
            "..................",
            ".OO..OO..........."
        ]
    }
    // The tail: dangling and swaying while awake, tucked in asleep.
    PixelArt {
        visible: root.lying && !root.asleep
        px: root.px
        flip: root.flip
        colors: root.colors
        rows: root.tailUp ? [
            "..................",
            "..................",
            "..................",
            "..................",
            "..................",
            "..................",
            "..............OBO.",
            "..............OBO.",
            "..............OBO.",
            ".............OBO..",
            ".............OBO..",
            "............OBO...",
            ".............O...."
        ] : [
            "..................",
            "..................",
            "..................",
            "..................",
            "..................",
            "..................",
            "..............OBO.",
            "..............OBO.",
            "..............OBO.",
            "..............OBO.",
            "..............OBO.",
            "..............OBO.",
            "...............O.."
        ]
    }
    PixelArt {
        visible: root.lying && root.asleep
        px: root.px
        flip: root.flip
        colors: root.colors
        rows: [
            "..................",
            "..................",
            "..................",
            "..................",
            "..................",
            "..................",
            ".............OOO..",
            "............O....."
        ]
    }

    // Sitting up.
    PixelArt {
        visible: !root.lying
        px: root.px
        flip: root.flip
        colors: root.colors
        rows: [
            ".O........O.....",
            ".OO......OO.....",
            ".OPO....OPO.....",
            ".OBBOOOOBBO.....",
            ".OBBBBBBBBO.....",
            "OBBBBBBBBBBO....",
            "OBBBBBBBBBBO....",
            "OBBBBBPBBBBO....",
            ".OBBBBBBBBO.....",
            "..OBBBBBBO......",
            ".OBBBBBBBBO.....",
            ".OBBLLLLBBO.....",
            "OBBBLLLLBBBO....",
            "OBBBLLLLBBBO....",
            "OBBBBBBBBBBO....",
            ".OOOOOOOOOO....."
        ]
    }
    PixelArt {
        visible: !root.lying
        px: root.px
        flip: root.flip
        colors: root.colors
        rows: root.blinking ? [
            "................",
            "................",
            "................",
            "................",
            "................",
            "................",
            "..OO....OO......"
        ] : [
            "................",
            "................",
            "................",
            "................",
            "................",
            "...E....E.......",
            "...E....E......."
        ]
    }
    PixelArt {
        visible: !root.lying
        px: root.px
        flip: root.flip
        colors: root.colors
        rows: root.tailUp ? [
            "..............O.",
            ".............OBO",
            ".............OBO",
            "............OBO.",
            "............OBO.",
            "...........OBO..",
            "..........OOO..."
        ] : [
            ".............OO.",
            "............OBBO",
            "...........OBBO.",
            "..........OOOO.."
        ]
        y: (root.tailUp ? 9 : 12) * root.px
    }

    // Asleep: z's drift up and away from the head, one at a time, beside
    // it rather than above (there's often a bough there).
    PixelArt {
        readonly property int t: clock.frame % 8
        readonly property int step: Math.floor(t / 2)

        visible: root.asleep && t < 6
        x: root.flip ? root.implicitWidth + step * root.px : -(4 + step) * root.px
        y: (1 - step) * root.px
        px: root.px
        colors: ({ "z": "#b5a8e0" })
        opacity: t < 4 ? 1 : 0.5
        rows: ["zzzz", "..z.", ".z..", "zzzz"]
    }
}
