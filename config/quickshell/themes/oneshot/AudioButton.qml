import QtQuick
import qs.core
import qs.modules.bar.widgets as W

// Dim red and crossed out when off, glowing accent while a player plays, dim
// otherwise.
Glyph {
    required property W.AudioButton control

    text: control.off ? "\u{F075F}" : "\u{F057E}"
    readonly property bool lit: !control.off && control.playing
    color: control.off ? Theme.palette.off : lit ? Theme.palette.accent : Theme.palette.dim

    Behavior on color {
        ColorAnimation { duration: 250 }
    }
}
