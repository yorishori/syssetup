import QtQuick
import qs.core

// The stars a window is conjured with. While `progress` runs 0 to 1, stars
// first pop in a little cluster at the point it comes from (`originX`,
// `originY`, in the parent's coordinates), then ride the window's edges out
// as it grows from there (`spread`, 0 to 1), leaving a short trail, and fade
// as it settles. Run backwards, the same: the window shrinks to the point
// and the last stars wink out there.
//
// Put it in the item that's scaled by `spread` around the origin: it undoes
// that scale so the stars keep their size and land where they should.
Item {
    id: root

    property real progress: 0
    property real spread: 0
    property real originX: 0
    property real originY: 0
    // The window's size at full spread, and which way it grows (1 down, -1
    // up).
    property real targetWidth: 0
    property real targetHeight: 0
    property int direction: 1
    property int px: Theme.get("pixel.scale") ?? 3

    readonly property real s: Math.max(0.04, spread)
    readonly property var colors: [Theme.palette.accent, Theme.palette.border, Theme.palette.dim]

    visible: progress > 0 && progress < 1

    // Each star: where on the window's outline it rides to (fractions of
    // its width from the middle, and of its height), when it pops (a share
    // of the first stretch), and its colour.
    readonly property var stars: [
        [-0.5, 0.0, 0.00, 0], [0.5, 0.0, 0.10, 1], [-0.5, 1.0, 0.05, 0],
        [0.5, 1.0, 0.15, 2], [0.0, 1.0, 0.08, 1], [-0.5, 0.5, 0.20, 2],
        [0.5, 0.5, 0.12, 0], [-0.2, 0.0, 0.18, 2], [0.25, 1.0, 0.03, 1]
    ]

    // How long the stars gather before the window starts growing.
    readonly property real gather: 0.25

    Repeater {
        model: root.stars

        Item {
            id: star

            required property var modelData
            required property int index

            // 0 to 1 over this star's life: it pops a little before or after
            // the others, flies out with the edges, and fades at the end.
            readonly property real born: modelData[2] * root.gather / 0.25
            readonly property real popped: Math.max(0, Math.min(1, (root.progress - born) / 0.08))
            readonly property real fade: 1 - Math.max(0, (root.progress - 0.78) / 0.22)
            // On screen, from the origin: a small burst while gathering, then
            // the point on the outline it rides, scaled with the window.
            readonly property real burstX: Math.cos(index * 2.4) * 4 * root.px * popped
            readonly property real burstY: Math.sin(index * 2.4) * 3 * root.px * popped
            readonly property real edgeX: modelData[0] * root.targetWidth * root.spread
            readonly property real edgeY: modelData[1] * root.targetHeight * root.spread * root.direction

            visible: popped > 0 && fade > 0
            opacity: fade
            // Undo the window's scale: place in its coordinates, at our size.
            x: root.originX + (burstX + edgeX) / root.s
            y: root.originY + (burstY + edgeY) / root.s
            scale: 1 / root.s
            transformOrigin: Item.TopLeft

            // The trail: two fading copies behind it, toward the origin.
            Repeater {
                model: [0.55, 0.25]

                Rectangle {
                    required property real modelData
                    required property int index

                    x: -(star.edgeX * (index + 1) * 0.12) - root.px / 2
                    y: -(star.edgeY * (index + 1) * 0.12) - root.px / 2
                    width: root.px
                    height: root.px
                    color: root.colors[star.modelData[3]]
                    opacity: modelData * Math.min(1, root.spread * 3)
                }
            }

            PixelArt {
                x: -width / 2
                y: -height / 2
                px: root.px
                colors: ({ "s": root.colors[star.modelData[3]], "c": "#fff6dc" })
                // It pops big, then settles to a twinkle.
                rows: star.popped < 1 || (Math.floor(root.progress * 20) + star.index) % 3 === 0
                    ? ["..s..", "..s..", "sscss", "..s..", "..s.."]
                    : [".s.", "scs", ".s."]
            }
        }
    }
}
