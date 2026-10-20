import QtQuick
import qs.core
import qs.modules.session as M

// A session button on the blast doors: an emergency stop with its head in
// the action's color and its glyph printed on it, a sticky note with its key
// number on the guard, its name on label tape above (an open guard hangs
// down over what's below). Hovered or selected,
// the guard swings open and the head lights; armed, it throbs.
Column {
    id: root

    required property M.SessionKey control
    readonly property color tone: Theme.values.display?.session?.[control.key] ?? Theme.palette.error

    spacing: 14

    Legend {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.control.label
        size: 16
    }
    EStop {
        anchors.horizontalCenter: parent.horizontalCenter
        size: 180
        color: root.tone
        glyph: root.control.glyph
        note: String(root.control.number)
        noteTilt: [-7, 5, -3, 8][(root.control.number - 1) % 4]
        open: root.control.hovered || root.control.current || root.control.armed
        pressed: root.control.pressed
        alarm: root.control.armed
    }
}
