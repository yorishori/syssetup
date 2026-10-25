import QtQuick
import qs.components

// What's being captured, over the frozen screen: `area` (in this item's
// coordinates; empty = nothing chosen yet). The skin sets it apart from the
// rest of the screen, shows its size and how to choose.
Skinned {
    property rect area: Qt.rect(0, 0, 0, 0)
    readonly property bool hasArea: area.width > 0 && area.height > 0
    // The area's being dragged out (it follows the hand; otherwise it moves
    // to a window or the screen).
    property bool moving: false
    // Chosen, and being marked up (screenshots).
    property bool marking: false
    // What for: "screenshot" or "screen" (a recording).
    property string kind: ""

    skin: "Selection"
}
