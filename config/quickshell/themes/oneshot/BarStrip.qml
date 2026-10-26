import QtQuick
import qs.core
import qs.modules.bar as B

// No strip: each group of keys floats on its own rounded island, and the
// wallpaper shows between them. Drops hang a little below.
Item {
    id: root

    required property B.BarStrip control
    readonly property real seam: -6

    Repeater {
        model: root.control.islands

        Box {
            required property var modelData
            readonly property var items: modelData.filter(i => i && i.visible && i.width > 0)
            readonly property real start: Math.min(...items.map(i => i.x))
            readonly property real end: Math.max(...items.map(i => i.x + i.width))

            x: start - 8
            y: 4
            width: end - start + 16
            height: root.height - 8
            roundness: height / 2
            fill: Theme.palette.bg
            raised: true
            visible: items.length > 0
        }
    }
}
