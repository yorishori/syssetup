import QtQuick
import qs.components

// What's around the chosen area while marking it up (screenshots): the
// tools, the inks, undo, done and cancel. The skin lays them out round
// `area`; it fills the screen.
Skinned {
    id: root

    property rect area: Qt.rect(0, 0, 0, 0)
    // [{ key, glyph }]; the one in hand.
    property var tools: []
    property string tool: ""
    property var inks: []
    property color ink
    property bool canUndo: false

    signal toolPicked(string key)
    signal inkPicked(color ink)
    signal undone
    signal done
    signal cancelled

    skin: "MarkTools"
}
