import QtQuick
import qs.components
import qs.core

// Bar glyph or short value. Calm (dim) by default; `lit` states glow like a
// panel lamp so they catch the eye without shouting.
StyledText {
    property bool lit: false

    color: Config.colors.dim
    glow: lit
    font.bold: true
    font.pixelSize: Config.font.size + 1
}
