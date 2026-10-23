import QtQuick
import qs.core
import qs.modules.bar.widgets as W

// A glyph key. Glows while the launcher is open.
W.BarLabel {
    required property W.LauncherButton control

    text: "\u{F08C7}"
    lit: control.active
    color: control.active ? Theme.palette.accent : control.hovered ? Theme.palette.fg : Theme.palette.dim
    font.pixelSize: Theme.font.size + 3

    Behavior on color {
        ColorAnimation { duration: 150 }
    }
}
