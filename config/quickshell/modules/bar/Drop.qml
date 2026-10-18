import QtQuick
import qs.components
import qs.core

// A panel that drops out of the bar under `anchorItem`, kept inside the
// window. `edge: "left"` / `"right"` pins it flush to that side of the screen
// instead, as if it grew out of the screen edge and the bar together.
//
// The skin draws and animates it: its `shownHeight` is the drop's height,
// `contentOpacity` the content's, and `overhang` how far it draws past its
// sides (kept clear of the screen edge when placing it).
Skinned {
    id: root

    required property Item anchorItem
    property bool open: false
    property int padding: 14
    property string edge: ""

    default property alias content: body.data

    readonly property real openHeight: body.childrenRect.height + 2 * padding
    readonly property bool flushLeft: edge === "left"
    readonly property bool flushRight: edge === "right"

    skin: "Drop"
    width: body.childrenRect.width + 2 * padding
    height: view?.shownHeight ?? 0
    visible: height > 0

    onOpenChanged: if (open) place()
    onAnchorItemChanged: if (open) place()
    onWidthChanged: if (open && edge) place()

    function place(): void {
        if (flushLeft) {
            x = 0;
            return;
        }
        if (flushRight) {
            x = parent.width - width;
            return;
        }
        if (!anchorItem)
            return;
        const margin = (view?.overhang ?? 0) + Config.bar.padding;
        const center = anchorItem.mapToItem(parent, anchorItem.width / 2, 0).x;
        x = Math.max(margin, Math.min(parent.width - width - margin, center - width / 2));
    }

    Item {
        anchors.fill: parent
        clip: true

        Item {
            id: body

            x: root.padding
            y: root.padding
            opacity: root.view?.contentOpacity ?? 1
        }
    }
}
