import QtQuick
import qs.core
import qs.modules.bar.widgets as W

// The power glyph. Glows while the session menu is open.
W.BarLabel {
    required property W.PowerButton control

    text: "\u{F0425}"
    lit: control.active
    color: control.active ? Theme.palette.accent : control.hovered ? Theme.palette.fg : Theme.palette.dim

    Behavior on color {
        ColorAnimation { duration: 150 }
    }
}
