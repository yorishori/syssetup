import QtQuick
import qs.core
import qs.modules.bar.widgets as W

// A cup carved into its bracket, empty and dim; on, it's filled, glows, and
// steams.
Item {
    id: root

    required property W.CaffeineButton control
    readonly property bool lit: control.on

    implicitWidth: cup.implicitWidth
    implicitHeight: cup.implicitHeight

    Ticker { id: clock }

    Glyph {
        id: cup

        text: root.control.on ? "\u{F0176}" : "\u{F06CA}"
        color: root.control.on ? Theme.palette.accent : root.control.hovered ? Theme.palette.fg : Theme.palette.dim

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    // Two wisps of steam, curling up out of it.
    Repeater {
        model: root.control.on ? [0, 3] : []

        PixelArt {
            required property int modelData
            readonly property int t: (clock.frame + modelData) % 6

            x: 4 + modelData * 2 + (t % 2) * 2
            y: -6 - t * 2
            px: 2
            opacity: t < 4 ? 0.7 : 0.3
            colors: ({ "s": Theme.palette.dim })
            rows: t % 2 ? ["s.", ".s"] : [".s", "s."]
        }
    }
}
