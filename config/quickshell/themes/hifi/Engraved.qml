import QtQuick
import qs.components as C
import qs.core

// Text silk-screened onto metal or a keycap: it sits on the surface with a
// faint shadow under it. Lit (glowing) text is backlit instead and casts none.
C.StyledText {
    id: root

    Text {
        z: -1
        y: 1
        width: root.width
        height: root.height
        text: root.text
        font: root.font
        color: Qt.alpha(Theme.palette.shadow, 0.85)
        horizontalAlignment: root.horizontalAlignment
        verticalAlignment: root.verticalAlignment
        elide: root.elide
        visible: !root.glow && root.text !== ""
    }
}
