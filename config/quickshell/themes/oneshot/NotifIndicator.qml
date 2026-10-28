import QtQuick
import qs.core
import qs.modules.bar.widgets as W

// Bell: dim when empty, accent with a count when something is waiting, dim
// red and crossed out in do-not-disturb.
Glyph {
    required property W.NotifIndicator control

    text: control.dnd ? "\u{F009B}" : control.count > 0 ? `\u{F009A} ${control.count}` : "\u{F009A}"
    readonly property bool lit: control.active || (!control.dnd && control.count > 0)
    color: control.dnd ? Theme.palette.off : lit ? Theme.palette.accent : Theme.palette.dim

    Behavior on color {
        ColorAnimation { duration: 150 }
    }
}
