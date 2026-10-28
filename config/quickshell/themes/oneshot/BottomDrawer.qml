import QtQuick
import qs.components as C
import qs.core

// An RPG window conjured off the bottom edge, like the panels under the bar:
// stars pop at the point it comes from, it grows up out of it with stars
// riding its edges, its contents fade in as it settles; closing runs that
// backwards. On the volume's (the OSD's) a little music note hops beside it
// while it's out, `overhang` making room; the others (clipboard, compose,
// …) are dressed by their frames, or twinkle on their corners.
Item {
    id: root

    required property C.BottomDrawer control

    readonly property bool osd: control.name === "osd"
    readonly property real overhang: osd ? 9 * px : 0
    readonly property real lift: 18
    readonly property int px: Theme.get("pixel.scale") ?? 3
    // 0 shut to 1 open, at an even pace; what moves takes its own curve
    // from it.
    property real progress: control.open ? 1 : 0

    Behavior on progress {
        NumberAnimation {
            duration: root.control.open ? 460 : 340
        }
    }

    // How far grown: nothing while the stars gather, then out of the point
    // with a little overshoot.
    readonly property real spread: {
        const t = Math.max(0, (progress - conjure.gather) / (1 - conjure.gather));
        const c = 1.3, u = t - 1;
        return t <= 0 ? 0 : 1 + (c + 1) * u * u * u + c * u * u;
    }
    readonly property real popScale: Math.max(0.04, spread)

    // The window's name on top, the contents moved down under it.
    readonly property string title: Theme.get(`titles.${control.name}`) ?? ""
    readonly property real titleHeight: title !== "" ? 34 : 0
    readonly property real contentShift: titleHeight

    readonly property real shownHeight: progress > 0 ? control.openHeight + titleHeight : 0
    // The contents (and title, sparkles) fade in as it settles.
    readonly property real contentOpacity: Math.max(0, (progress - 0.75) / 0.25)

    Ticker {
        id: clock

        fps: 6
    }

    Frame {
        id: frame

        anchors.fill: parent
        opacity: Math.min(1, root.spread * 6)
        kind: root.control.name
        trim: root.contentOpacity
    }

    C.StyledText {
        x: root.control.padding
        y: root.control.padding - 4
        text: root.title
        visible: root.title !== ""
        opacity: root.contentOpacity
        color: Theme.palette.accent
        font.pixelSize: Theme.font.size + 6
        font.weight: Font.DemiBold
    }

    PixelArt {
        x: root.width + 2 * root.px
        y: (clock.frame % 4 < 2 ? 1 : 0) * root.px
        px: root.px
        visible: root.osd
        opacity: root.contentOpacity
        colors: ({ "n": Theme.palette.dim })
        rows: [
            "...nn.",
            "...n.n",
            "...n..",
            "...n..",
            ".nnn..",
            "nnnn..",
            "nnnn..",
            ".nn..."
        ]
    }

    Repeater {
        model: frame.dressed ? [] : (root.osd ? [] : [[-1, -1, 0], [1, -1, 5]])

        PixelArt {
            required property var modelData

            x: modelData[0] < 0 ? -root.px : root.width - 2 * root.px
            y: -root.px
            px: root.px
            colors: ({ "s": Theme.palette.accent })
            rows: [".s.", "sss", ".s."]
            opacity: root.contentOpacity * ((clock.frame + modelData[2]) % 18 < 3 ? 0.25 : 0.9)
        }
    }

    Conjure {
        id: conjure

        progress: root.progress
        spread: root.spread
        originX: root.width / 2
        originY: root.height
        targetWidth: root.width
        targetHeight: root.height
        direction: -1
    }
}
