import QtQuick
import qs.core
import qs.modules.bar.widgets as W

// An empty cup, dim; on, it's filled and glows.
W.BarLabel {
    required property W.CaffeineButton control

    text: control.on ? "\u{F0176}" : "\u{F06CA}"
    lit: control.on
    color: control.on ? Theme.palette.accent : control.hovered ? Theme.palette.fg : Theme.palette.dim

    Behavior on color {
        ColorAnimation { duration: 150 }
    }
}
