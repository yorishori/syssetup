import QtQuick
import qs.core
import qs.modules.session as M

// A session button on the blast doors: an emergency stop with its head in
// the action's color and its glyph printed on it, its key number and name on
// label tape below. Hovered or selected, the guard swings up and the head
// lights; armed, it throbs.
Column {
    id: root

    required property M.SessionKey control
    readonly property color tone: Theme.values.display?.session?.[control.key] ?? Theme.palette.error

    spacing: 14

    EStop {
        anchors.horizontalCenter: parent.horizontalCenter
        size: 180
        color: root.tone
        glyph: root.control.glyph
        // Dim until it's hovered, selected or armed.
        rest: 2.8
        open: root.control.hovered || root.control.current || root.control.armed
        pressed: root.control.pressed
        alarm: root.control.armed
    }
    Legend {
        anchors.horizontalCenter: parent.horizontalCenter
        text: `${root.control.number} ${root.control.label}`
        size: 16
    }
}
