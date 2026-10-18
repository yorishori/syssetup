import QtQuick
import QtQuick.Shapes
import qs.core
import qs.modules.bar as B

// Slides out of the bar like a drawer from a console: same fill as the bar,
// angled shoulders where it joins, cut bottom corners; the bar's hairline
// continues around it. A flush side has no shoulder, cut or hairline.
Item {
    id: root

    required property B.Drop control

    readonly property int shoulder: 10
    readonly property real overhang: shoulder
    property real shownHeight: control.open ? control.openHeight : 0
    property real contentOpacity: control.open ? 1 : 0

    Behavior on shownHeight {
        NumberAnimation {
            duration: root.control.open ? 300 : 150
            easing.type: root.control.open ? Easing.OutBack : Easing.InQuad
            easing.overshoot: 0.9
        }
    }
    Behavior on contentOpacity {
        NumberAnimation { duration: root.control.open ? 180 : 60 }
    }

    Shape {
        id: housing

        // Shrink the shoulders and cuts with the height so the outline stays
        // valid while the drawer is still sliding out. Flush sides have none.
        readonly property real s: Math.min(root.shoulder, root.height)
        readonly property real c: Math.min(Theme.values.shape.cut * 2, root.height / 2)
        readonly property real sL: root.control.flushLeft ? 0 : s
        readonly property real sR: root.control.flushRight ? 0 : s
        readonly property real cL: root.control.flushLeft ? 0 : c
        readonly property real cR: root.control.flushRight ? 0 : c
        // Hairline x positions; on a flush side it goes just off-screen.
        readonly property real xL: root.control.flushLeft ? -1 : 0.5
        readonly property real xR: root.control.flushRight ? root.width + 1 : root.width - 0.5

        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: Theme.palette.bg
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
            strokeColor: Theme.palette.border
            strokeWidth: Theme.values.shape.border
            joinStyle: ShapePath.MiterJoin
            capStyle: ShapePath.FlatCap

            startX: root.control.flushLeft ? -1 : -housing.s
            startY: 0.5

            PathLine { x: housing.xL; y: housing.sL }
            PathLine { x: housing.xL; y: root.height - housing.cL }
            PathLine { x: housing.cL; y: root.height - 0.5 }
            PathLine { x: root.width - housing.cR; y: root.height - 0.5 }
            PathLine { x: housing.xR; y: root.height - housing.cR }
            PathLine { x: housing.xR; y: housing.sR }
            PathLine { x: root.control.flushRight ? root.width + 1 : root.width + housing.s; y: 0.5 }
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
}
