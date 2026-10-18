import QtQuick
import qs.components
import qs.core

// Bar glyph or short value. Calm (dim) by default; `lit` states glow like a
// panel lamp so they catch the eye without shouting.
StyledText {
    property bool lit: false

    color: Theme.palette.dim
    glow: lit
    font.bold: true
    font.pixelSize: Theme.font.size + 1
}
