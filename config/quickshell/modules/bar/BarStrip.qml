import QtQuick
import qs.components

// The bar itself, along the top edge; its widgets go in as children. `seam`
// is how far the drops overlap its bottom edge (so an outline can run on
// around them).
Skinned {
    readonly property real seam: view?.seam ?? 0

    skin: "BarStrip"
}
