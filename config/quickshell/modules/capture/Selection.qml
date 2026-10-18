import QtQuick
import qs.components

// What's being captured, over the frozen screen: `area` (in this item's
// coordinates; empty = nothing chosen yet). The skin sets it apart from the
// rest of the screen.
Skinned {
    property rect area: Qt.rect(0, 0, 0, 0)
    readonly property bool hasArea: area.width > 0 && area.height > 0

    skin: "Selection"
}
