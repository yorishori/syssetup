import QtQuick
import qs.components as C
import qs.core

// An RPG window rising off the bottom edge in four steps; its contents
// show once it's up. A little music note hops beside it while it's out
// (it's the volume's window); `overhang` makes room for it.
Item {
    id: root

    required property C.BottomDrawer control

    readonly property real overhang: 9 * px
    readonly property real lift: 18
    readonly property int px: Theme.get("pixel.scale") ?? 3
    readonly property int steps: 4
    property int step: 0

    readonly property real shownHeight: step >= steps ? control.openHeight
        : Math.round(control.openHeight * step / steps / px) * px
    readonly property real contentOpacity: step >= steps ? 1 : 0

    Timer {
        interval: 45
        repeat: true
        running: root.step !== (root.control.open ? root.steps : 0)
        onTriggered: root.step += root.control.open ? 1 : -1
    }

    Ticker {
        id: clock

        fps: 6
    }

    Frame {
        anchors.fill: parent
    }

    PixelArt {
        x: root.width + 2 * root.px
        y: (clock.frame % 4 < 2 ? 1 : 0) * root.px
        px: root.px
        visible: root.step >= root.steps
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
}
