import QtQuick
import QtQuick.Shapes
import qs.components
import qs.core

// A panel that slides out of the bar like a drawer from a console. Same fill
// as the bar, angled shoulders where it joins, cut bottom corners; the bar's
// hairline edge continues around it. Sits under `anchorItem`, kept inside the
// window.
//
// `edge: "left"` / `"right"` pins it flush to that side of the screen instead:
// no shoulder, corner cut or hairline on that side, as if it grew out of the
// screen edge and the bar together.
Item {
    id: root

    required property Item anchorItem
    property bool open: false
    property int padding: 14
    property int shoulder: 10
    property string edge: ""

    default property alias content: body.data

    readonly property real openHeight: body.childrenRect.height + 2 * padding
    readonly property bool flushLeft: edge === "left"
    readonly property bool flushRight: edge === "right"

    width: body.childrenRect.width + 2 * padding
    height: open ? openHeight : 0
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
        const margin = shoulder + Config.bar.padding;
        const center = anchorItem.mapToItem(parent, anchorItem.width / 2, 0).x;
        x = Math.max(margin, Math.min(parent.width - width - margin, center - width / 2));
    }

    Behavior on height {
        NumberAnimation {
            duration: root.open ? 300 : 150
            easing.type: root.open ? Easing.OutBack : Easing.InQuad
            easing.overshoot: 0.9
        }
    }

    Shape {
        id: housing

        // Shrink the shoulders and cuts with the height so the outline stays
        // valid while the drawer is still sliding out. Flush sides have none.
        readonly property real s: Math.min(root.shoulder, root.height)
        readonly property real c: Math.min(Config.shape.cut * 2, root.height / 2)
        readonly property real sL: root.flushLeft ? 0 : s
        readonly property real sR: root.flushRight ? 0 : s
        readonly property real cL: root.flushLeft ? 0 : c
        readonly property real cR: root.flushRight ? 0 : c
        // Hairline x positions; on a flush side it goes just off-screen.
        readonly property real xL: root.flushLeft ? -1 : 0.5
        readonly property real xR: root.flushRight ? root.width + 1 : root.width - 0.5

        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: Config.colors.bg
            strokeWidth: -1

            startX: -housing.sL
            startY: 0

            PathLine { x: 0; y: housing.sL }
            PathLine { x: 0; y: root.height - housing.cL }
            PathLine { x: housing.cL; y: root.height }
            PathLine { x: root.width - housing.cR; y: root.height }
            PathLine { x: root.width; y: root.height - housing.cR }
            PathLine { x: root.width; y: housing.sR }
            PathLine { x: root.width + housing.sR; y: 0 }
            PathLine { x: -housing.sL; y: 0 }
        }

        // Hairline: continues the bar's bottom edge down and around the drawer.
        ShapePath {
            fillColor: "transparent"
            strokeColor: Config.colors.border
            strokeWidth: Config.shape.border
            joinStyle: ShapePath.MiterJoin
            capStyle: ShapePath.FlatCap

            startX: root.flushLeft ? -1 : -housing.s
            startY: 0.5

            PathLine { x: housing.xL; y: housing.sL }
            PathLine { x: housing.xL; y: root.height - housing.cL }
            PathLine { x: housing.cL; y: root.height - 0.5 }
            PathLine { x: root.width - housing.cR; y: root.height - 0.5 }
            PathLine { x: housing.xR; y: root.height - housing.cR }
            PathLine { x: housing.xR; y: housing.sR }
            PathLine { x: root.flushRight ? root.width + 1 : root.width + housing.s; y: 0.5 }
        }
    }

    Item {
        anchors {
            fill: parent
            topMargin: 1
            bottomMargin: housing.c
            leftMargin: 1
            rightMargin: 1
        }
        clip: true

        Scanlines {
            anchors.fill: parent
        }
    }

    Item {
        anchors.fill: parent
        clip: true

        Item {
            id: body

            x: root.padding
            y: root.padding
            opacity: root.open ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: root.open ? 180 : 60 }
            }
        }
    }
}
