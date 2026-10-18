import QtQuick
import qs.components

// The bar itself, along the top edge; its widgets go in as children.
// `islands`: the groups of keys, each a list of the items in it.
// `seam` (from the skin): how far the drops overlap its bottom edge (so an
// outline can run on around them); negative leaves a gap.
Skinned {
    property var islands: []
    readonly property real seam: view?.seam ?? 0

    skin: "BarStrip"
}
