import QtQuick
import qs.components as C
import qs.core

// A key on a keypad; the current one is latched in and backlit.
Item {
    id: root

    required property C.Tile control

    Key {
        anchors {
            fill: parent
            margins: 3
        }
        down: root.control.current
        hovered: root.control.hovered
        tint: Qt.darker(Theme.palette.surface, 1.08)
        glowColor: root.control.current ? Theme.palette.accent : "transparent"
    }
}
