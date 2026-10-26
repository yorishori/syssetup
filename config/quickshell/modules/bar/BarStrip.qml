import QtQuick
import qs.components

// The bar itself, along the top edge; its widgets go in as children.
// `islands`: the groups of keys, each a list of the items in it.
// `openDrop`: the panel open under it ("" for none), for skins that change
// with it.
// `seam` (from the skin): how far the drops overlap its bottom edge (so an
// outline can run on around them); negative leaves a gap.
// `offset` (from the skin): how far below the strip's middle the widgets
// sit, for skins that hang them lower (oneshot's signs under a bough).
Skinned {
    property var islands: []
    property string openDrop: ""
    readonly property real seam: view?.seam ?? 0
    readonly property real offset: view?.offset ?? 0

    skin: "BarStrip"
}
