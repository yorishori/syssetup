import QtQuick
import qs.components as C
import qs.core

// An RPG window rising off the bottom edge in four steps; its contents
// show once it's up. On the volume's (the OSD's) a little music note hops
// beside it while it's out, `overhang` making room; the others (clipboard,
// compose, …) twinkle on their corners like the panels.
Item {
    id: root

    required property C.BottomDrawer control

    readonly property bool osd: control.name === "osd"
    readonly property real overhang: osd ? 9 * px : 0
    readonly property real lift: 18
    readonly property int px: Theme.get("pixel.scale") ?? 3
    readonly property int steps: 4
    property int step: 0

    // The window's name on top, the contents moved down under it.
    readonly property string title: Theme.get(`titles.${control.name}`) ?? ""
    readonly property real titleHeight: title !== "" ? 34 : 0
    readonly property real contentShift: titleHeight

    readonly property real shownHeight: step >= steps ? control.openHeight + titleHeight
        : Math.round((control.openHeight + titleHeight) * step / steps / px) * px
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

    C.StyledText {
        x: root.control.padding
        y: root.control.padding - 4
        text: root.title
        visible: root.title !== "" && root.step >= root.steps
        color: Theme.palette.accent
        font.pixelSize: Theme.font.size + 6
        font.weight: Font.DemiBold
    }

    PixelArt {
        x: root.width + 2 * root.px
        y: (clock.frame % 4 < 2 ? 1 : 0) * root.px
        px: root.px
        visible: root.osd && root.step >= root.steps
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
        model: root.osd ? [] : [[-1, -1, 0], [1, -1, 5]]

        PixelArt {
            required property var modelData

            x: modelData[0] < 0 ? -root.px : root.width - 2 * root.px
            y: -root.px
            px: root.px
            colors: ({ "s": Theme.palette.accent })
            rows: [".s.", "sss", ".s."]
            visible: root.step >= root.steps
            opacity: (clock.frame + modelData[2]) % 18 < 3 ? 0.25 : 0.9
        }
    }
}
