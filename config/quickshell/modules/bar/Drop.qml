import QtQuick
import qs.components
import qs.core

// A panel that drops out of the bar under `anchorItem`, kept inside the
// window. `edge: "left"` / `"right"` pins it flush to that side of the screen
// instead, as if it grew out of the screen edge and the bar together.
//
// `name` is the panel it holds, for skins that open some differently.
//
// The skin draws and animates it: its `shownHeight` is the drop's height,
// `contentOpacity` the content's, `contentShift` moves the content down (a
// drawer's content slides out with it), `popScale` the drop's scale, `swing`
// turns it on a hinge along its top edge (degrees; 0 = hanging flat),
// `overhang` how far it draws past its sides (kept clear of the screen edge
// when placing it), `inset` how far a flush drop stays off the screen edge,
// `clipContent` false lets its content draw past its edges and `behindBar`
// puts it behind the bar (for what comes out from behind it).
Skinned {
    id: root

    required property Item anchorItem
    property bool open: false
    property int padding: 14
    property string edge: ""
    property string name: ""

    default property alias content: body.data

    readonly property real openHeight: body.childrenRect.height + 2 * padding
    readonly property bool flushLeft: edge === "left"
    readonly property bool flushRight: edge === "right"

    skin: "Drop"
    z: view?.behindBar ? -1 : 0
    width: body.childrenRect.width + 2 * padding
    height: view?.shownHeight ?? 0
    visible: height > 0
    scale: view?.popScale ?? 1
    transformOrigin: Item.Top
    transform: Rotation {
        origin.x: root.width / 2
        axis { x: 1; y: 0; z: 0 }
        angle: root.view?.swing ?? 0
    }

    onOpenChanged: if (open) place()
    onAnchorItemChanged: if (open) place()
    onWidthChanged: if (open && edge) place()

    function place(): void {
        const inset = view?.inset ?? 0;
        if (flushLeft) {
            x = inset;
            return;
        }
        if (flushRight) {
            x = parent.width - width - inset;
            return;
        }
        if (!anchorItem)
            return;
        const margin = (view?.overhang ?? 0) + Config.bar.padding;
        const center = anchorItem.mapToItem(parent, anchorItem.width / 2, 0).x;
        x = Math.max(margin, Math.min(parent.width - width - margin, center - width / 2));
    }

    // Clicks nothing on the drop takes stop here, so they don't fall through
    // to the bar's click-outside catcher underneath (Sway) and close it.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
    }

    Item {
        anchors.fill: parent
        clip: root.view?.clipContent ?? true

        Item {
            id: body

            x: root.padding
            y: root.padding + (root.view?.contentShift ?? 0)
            opacity: root.view?.contentOpacity ?? 1
        }
    }
}
