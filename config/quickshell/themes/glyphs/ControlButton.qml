import QtQuick
import qs.core
import qs.modules.bar.widgets as W

// A glyph key. Glows while the control center is open.
W.BarLabel {
    required property W.ControlButton control

    text: "\u{F062E}"
    lit: control.active
    color: control.active ? Theme.palette.accent : control.hovered ? Theme.palette.fg : Theme.palette.dim

    Behavior on color {
        ColorAnimation { duration: 150 }
    }
}
