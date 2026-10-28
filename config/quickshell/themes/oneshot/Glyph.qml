import QtQuick
import qs.components as C
import qs.core

// A label whose leading Nerd Font glyph is drawn as the theme's pixel icon
// (Sprites.glyphs), in its colour, followed by the rest of the text. Text
// without a known glyph is just text. For the bar, buttons and keys.
Row {
    id: root

    property string text
    property color color: Theme.palette.fg
    property int pixelSize: Theme.font.size
    // Screen pixels per icon pixel: 2 (18 px icons) unless asked for more.
    property int px: 2
    property bool bold: false

    readonly property string first: text.length ? String.fromCodePoint(text.codePointAt(0)) : ""
    readonly property string icon: Sprites.glyphs[first] ?? ""
    readonly property string rest: (icon ? text.slice(first.length) : text).trim()

    function rgba(c: color, a: real): string {
        return `rgba(${Math.round(c.r * 255)},${Math.round(c.g * 255)},${Math.round(c.b * 255)},${c.a * a})`;
    }

    spacing: 6

    PixelArt {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.icon !== ""
        px: root.px
        rows: Sprites.icons[root.icon] ?? []
        colors: ({ "x": root.rgba(root.color, 1), "-": root.rgba(root.color, 0.45) })
    }
    C.StyledText {
        anchors.verticalCenter: parent.verticalCenter
        text: root.rest
        visible: text !== ""
        color: root.color
        font.pixelSize: root.pixelSize
        font.bold: root.bold
    }
}
